from fastapi import FastAPI, HTTPException, Depends, status, Query
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from pydantic import BaseModel, EmailStr
from typing import List, Optional, Dict, Any
import pyodbc
import firebase_admin
from firebase_admin import credentials, auth
import json
from datetime import datetime, timedelta
import logging
import base64
import uuid
import os
import io
from PIL import Image

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(title="Internee.pk Learning App API", version="1.0.0")

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Security
security = HTTPBearer()



def get_db_connection():
    try:
        conn = pyodbc.connect(
            "DRIVER={ODBC Driver 17 for SQL Server};"
            "SERVER=DESKTOP-8BL3MIG\\SQLEXPRESS;"
            "DATABASE=learning_app;"
            "Trusted_Connection=yes;"
        )
        return conn
    except Exception as e:
        logger.error(f"Database connection failed: {e}")
        raise HTTPException(status_code=500, detail="Database connection failed")

async def verify_firebase_token(credentials: HTTPAuthorizationCredentials = Depends(security)):
    try:
        token = credentials.credentials
        decoded_token = auth.verify_id_token(token)
        return decoded_token
    except Exception as e:
        logger.error(f"Token verification failed: {e}")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid authentication token"
        )


# Add this function to main.py after the verify_firebase_token function
async def get_or_create_user(current_user: dict):
    """Get user from database or create if doesn't exist"""
    conn = get_db_connection()
    cursor = conn.cursor()
    
    try:
        cursor.execute("SELECT id FROM users WHERE firebase_uid = ?", current_user["uid"])
        user_row = cursor.fetchone()
        
        if user_row:
            return user_row.id
        
        # Create user if doesn't exist
        email = current_user.get("email", f"{current_user['uid']}@unknown.com")
        display_name = current_user.get("name", "Unknown User")
        
        cursor.execute("""
            INSERT INTO users (firebase_uid, email, display_name, profile_picture_data)
            OUTPUT INSERTED.id VALUES (?, ?, ?, ?)
        """, current_user["uid"], email, display_name, None)
        
        new_user = cursor.fetchone()
        conn.commit()
        logger.info(f"Auto-created user {current_user['uid']} with ID {new_user.id}")
        
        return new_user.id
        
    except Exception as e:
        conn.rollback()
        logger.error(f"Failed to get or create user: {e}")
        raise HTTPException(status_code=500, detail="User setup failed")
    finally:
        conn.close()



def process_profile_image(base64_image_data: str) -> str:
    """Process and optimize the profile image. Returns the base64 encoded image data."""
    try:
        # Decode base64 image
        image_data = base64.b64decode(base64_image_data)
        
        # Open image with PIL
        image = Image.open(io.BytesIO(image_data))
        
        # Convert to RGB if necessary (for PNG with transparency)
        if image.mode != 'RGB':
            image = image.convert('RGB')
        
        # Resize image to max 400x400 while maintaining aspect ratio
        image.thumbnail((400, 400), Image.Resampling.LANCZOS)
        
        # Save to bytes
        output_buffer = io.BytesIO()
        image.save(output_buffer, format='JPEG', quality=85, optimize=True)
        
        # Encode back to base64
        processed_image_data = base64.b64encode(output_buffer.getvalue()).decode('utf-8')
        
        return processed_image_data
        
    except Exception as e:
        logger.error(f"Image processing failed: {e}")
        raise HTTPException(status_code=400, detail="Invalid image format")

# Pydantic Models
class UserCreate(BaseModel):
    firebase_uid: str
    email: EmailStr
    display_name: Optional[str] = None
    profile_picture: Optional[str] = None

class UserUpdate(BaseModel):
    display_name: Optional[str] = None
    profile_picture: Optional[str] = None

class UserResponse(BaseModel):
    id: int
    firebase_uid: str
    email: str
    display_name: Optional[str]
    profile_picture: Optional[str]
    created_at: datetime

class CategoryResponse(BaseModel):
    id: int
    name: str
    description: Optional[str]
    icon_url: Optional[str]
    color: Optional[str]

class CourseResponse(BaseModel):
    id: int
    title: str
    description: Optional[str]
    thumbnail_url: Optional[str]
    category_id: Optional[int]
    category_name: Optional[str]
    instructor_name: Optional[str]
    duration_minutes: Optional[int]
    level: Optional[str]
    price: Optional[float]
    is_free: bool
    rating: Optional[float]
    total_ratings: int
    total_enrollments: int
    is_enrolled: bool = False
    progress_percentage: float = 0.0
    course_url: Optional[str] = None

class LessonResponse(BaseModel):
    id: int
    course_id: int
    title: str
    description: Optional[str]
    video_url: Optional[str]
    duration_seconds: Optional[int]
    order_index: int
    is_preview: bool
    is_watched: bool = False
    watched_duration: int = 0

class QuizResponse(BaseModel):
    id: int
    course_id: int
    lesson_id: Optional[int]
    title: str
    description: Optional[str]
    total_questions: int
    time_limit_minutes: Optional[int]
    passing_score_percentage: float
    attempts_allowed: int
    user_attempts: int = 0
    best_score: Optional[float] = None
    is_passed: bool = False

class QuestionResponse(BaseModel):
    id: int
    question_text: str
    question_type: str
    points: int
    order_index: int
    options: List[Dict[str, Any]]

class SubmitQuizRequest(BaseModel):
    quiz_id: int
    answers: List[Dict[str, Any]]
    time_taken_seconds: int

class EnrollRequest(BaseModel):
    course_id: int

class UpdateProgressRequest(BaseModel):
    lesson_id: int
    watched_duration_seconds: int
    is_completed: bool = False

# Initialize Firebase
initialize_firebase()

# API Endpoints

@app.get("/")
async def root():
    return {"message": "Internee.pk Learning App API"}

# Auth Endpoints
@app.post("/auth/register", response_model=UserResponse)
async def register_user(user_data: UserCreate):
    conn = get_db_connection()
    cursor = conn.cursor()
    
    try:
        cursor.execute("SELECT id FROM users WHERE firebase_uid = ?", user_data.firebase_uid)
        existing_user = cursor.fetchone()
        
        if existing_user:
            raise HTTPException(status_code=400, detail="User already exists")
        
        processed_profile_picture = None
        if user_data.profile_picture:
            try:
                processed_profile_picture = process_profile_image(user_data.profile_picture)
            except Exception as e:
                logger.warning(f"Profile picture processing failed during registration: {e}")
        
        cursor.execute("""
            INSERT INTO users (firebase_uid, email, display_name, profile_picture_data)
            OUTPUT INSERTED.* VALUES (?, ?, ?, ?)
        """, user_data.firebase_uid, user_data.email, user_data.display_name, processed_profile_picture)
        
        row = cursor.fetchone()
        conn.commit()
        
        return UserResponse(
            id=row.id,
            firebase_uid=row.firebase_uid,
            email=row.email,
            display_name=row.display_name,
            profile_picture=row.profile_picture_data,
            created_at=row.created_at
        )
    except Exception as e:
        conn.rollback()
        logger.error(f"Registration failed: {e}")
        raise HTTPException(status_code=500, detail="Registration failed")
    finally:
        conn.close()

@app.get("/auth/profile", response_model=UserResponse)
async def get_user_profile(current_user: dict = Depends(verify_firebase_token)):
    conn = get_db_connection()
    cursor = conn.cursor()
    
    try:
        cursor.execute("SELECT * FROM users WHERE firebase_uid = ?", current_user["uid"])
        row = cursor.fetchone()
        
        if not row:
            raise HTTPException(status_code=404, detail="User not found")
        
        return UserResponse(
            id=row.id,
            firebase_uid=row.firebase_uid,
            email=row.email,
            display_name=row.display_name,
            profile_picture=row.profile_picture_data,
            created_at=row.created_at
        )
    finally:
        conn.close()

@app.put("/auth/profile", response_model=UserResponse)
async def update_user_profile(
    user_data: UserUpdate,
    current_user: dict = Depends(verify_firebase_token)
):
    conn = get_db_connection()
    cursor = conn.cursor()
    
    try:
        cursor.execute("SELECT id FROM users WHERE firebase_uid = ?", current_user["uid"])
        user_row = cursor.fetchone()
        
        if not user_row:
            raise HTTPException(status_code=404, detail="User not found")
        user_id = user_row.id
        
        processed_profile_picture = None
        if user_data.profile_picture is not None:
            if user_data.profile_picture == "":
                processed_profile_picture = None
            else:
                try:
                    processed_profile_picture = process_profile_image(user_data.profile_picture)
                except Exception as e:
                    raise HTTPException(status_code=400, detail=f"Image processing failed: {str(e)}")
        
        update_fields = []
        update_values = []
        
        if user_data.display_name is not None:
            update_fields.append("display_name = ?")
            update_values.append(user_data.display_name.strip())
        
        if user_data.profile_picture is not None:
            update_fields.append("profile_picture_data = ?")
            update_values.append(processed_profile_picture)
        
        if not update_fields:
            cursor.execute("SELECT * FROM users WHERE id = ?", user_id)
            row = cursor.fetchone()
        else:
            update_values.append(user_id)
            update_query = f"UPDATE users SET {', '.join(update_fields)} WHERE id = ?"
            cursor.execute(update_query, update_values)
            conn.commit()
            
            cursor.execute("SELECT * FROM users WHERE id = ?", user_id)
            row = cursor.fetchone()
        
        if not row:
            raise HTTPException(status_code=404, detail="User not found")
        
        return UserResponse(
            id=row.id,
            firebase_uid=row.firebase_uid,
            email=row.email,
            display_name=row.display_name,
            profile_picture=row.profile_picture_data,
            created_at=row.created_at
        )
    except Exception as e:
        conn.rollback()
        logger.error(f"Profile update failed: {e}")
        raise HTTPException(status_code=500, detail="Profile update failed")
    finally:
        conn.close()

@app.get("/categories", response_model=List[CategoryResponse])
async def get_categories():
    conn = get_db_connection()
    cursor = conn.cursor()
    
    try:
        cursor.execute("SELECT * FROM categories WHERE is_active = 1 ORDER BY name")
        rows = cursor.fetchall()
        
        return [CategoryResponse(
            id=row.id,
            name=row.name,
            description=row.description,
            icon_url=row.icon_url,
            color=row.color
        ) for row in rows]
    finally:
        conn.close()

@app.get("/courses", response_model=List[CourseResponse])
async def get_courses(
    category_id: Optional[int] = Query(None, description="Filter by category ID"),
    search: Optional[str] = Query(None, description="Search in title, description, instructor"),
    level: Optional[str] = Query(None, description="Filter by difficulty level"),
    is_free: Optional[bool] = Query(None, description="Filter by free/paid courses"),
    min_rating: Optional[float] = Query(None, description="Minimum rating filter"),
    sort_by: Optional[str] = Query("newest", description="Sort by: newest, popular, rating"),
    current_user: dict = Depends(verify_firebase_token)
):
    conn = get_db_connection()
    cursor = conn.cursor()
    
    try:
        cursor.execute("SELECT id FROM users WHERE firebase_uid = ?", current_user["uid"])
        user_row = cursor.fetchone()
        user_id = user_row.id if user_row else None
        
        base_query = """
            SELECT c.*, cat.name as category_name,
                   CASE WHEN ue.user_id IS NOT NULL THEN 1 ELSE 0 END as is_enrolled,
                   ISNULL(ue.progress_percentage, 0) as progress_percentage
            FROM courses c
            LEFT JOIN categories cat ON c.category_id = cat.id
            LEFT JOIN user_enrollments ue ON c.id = ue.course_id AND ue.user_id = ?
            WHERE c.is_active = 1
        """
        params = [user_id]
        
        if category_id:
            base_query += " AND c.category_id = ?"
            params.append(category_id)
        
        if search:
            base_query += " AND (c.title LIKE ? OR c.description LIKE ? OR c.instructor_name LIKE ?)"
            search_term = f"%{search}%"
            params.extend([search_term, search_term, search_term])
        
        if level:
            base_query += " AND c.level = ?"
            params.append(level)
        
        if is_free is not None:
            base_query += " AND c.is_free = ?"
            params.append(is_free)
        
        if min_rating:
            base_query += " AND c.rating >= ?"
            params.append(min_rating)
        
        if sort_by == "popular":
            base_query += " ORDER BY c.total_enrollments DESC"
        elif sort_by == "rating":
            base_query += " ORDER BY c.rating DESC, c.total_ratings DESC"
        else:
            base_query += " ORDER BY c.created_at DESC"
        
        cursor.execute(base_query, params)
        rows = cursor.fetchall()
        
        return [CourseResponse(
            id=row.id,
            title=row.title,
            description=row.description,
            thumbnail_url=row.thumbnail_url,
            category_id=row.category_id,
            category_name=row.category_name,
            instructor_name=row.instructor_name,
            duration_minutes=row.duration_minutes,
            level=row.level,
            price=float(row.price) if row.price else 0.0,
            is_free=bool(row.is_free),
            rating=float(row.rating) if row.rating else 0.0,
            total_ratings=row.total_ratings,
            total_enrollments=row.total_enrollments,
            is_enrolled=bool(row.is_enrolled),
            progress_percentage=float(row.progress_percentage),
            course_url=row.course_url
        ) for row in rows]
    finally:
        conn.close()

@app.get("/courses/featured", response_model=List[CourseResponse])
async def get_featured_courses(current_user: dict = Depends(verify_firebase_token)):
    conn = get_db_connection()
    cursor = conn.cursor()
    
    try:
        cursor.execute("SELECT id FROM users WHERE firebase_uid = ?", current_user["uid"])
        user_row = cursor.fetchone()
        user_id = user_row.id if user_row else None
        
        cursor.execute("""
            SELECT c.*, cat.name as category_name,
                   CASE WHEN ue.user_id IS NOT NULL THEN 1 ELSE 0 END as is_enrolled,
                   ISNULL(ue.progress_percentage, 0) as progress_percentage
            FROM courses c
            LEFT JOIN categories cat ON c.category_id = cat.id
            LEFT JOIN user_enrollments ue ON c.id = ue.course_id AND ue.user_id = ?
            WHERE c.is_active = 1 AND c.rating >= 4.5 AND c.total_enrollments > 100000
            ORDER BY c.rating DESC, c.total_enrollments DESC
        """, user_id)
        
        rows = cursor.fetchall()
        
        return [CourseResponse(
            id=row.id,
            title=row.title,
            description=row.description,
            thumbnail_url=row.thumbnail_url,
            category_id=row.category_id,
            category_name=row.category_name,
            instructor_name=row.instructor_name,
            duration_minutes=row.duration_minutes,
            level=row.level,
            price=float(row.price) if row.price else 0.0,
            is_free=bool(row.is_free),
            rating=float(row.rating) if row.rating else 0.0,
            total_ratings=row.total_ratings,
            total_enrollments=row.total_enrollments,
            is_enrolled=bool(row.is_enrolled),
            progress_percentage=float(row.progress_percentage),
            course_url=row.course_url
        ) for row in rows]
    finally:
        conn.close()

@app.get("/courses/popular", response_model=List[CourseResponse])
async def get_popular_courses(current_user: dict = Depends(verify_firebase_token)):
    conn = get_db_connection()
    cursor = conn.cursor()
    
    try:
        cursor.execute("SELECT id FROM users WHERE firebase_uid = ?", current_user["uid"])
        user_row = cursor.fetchone()
        user_id = user_row.id if user_row else None
        
        cursor.execute("""
            SELECT c.*, cat.name as category_name,
                   CASE WHEN ue.user_id IS NOT NULL THEN 1 ELSE 0 END as is_enrolled,
                   ISNULL(ue.progress_percentage, 0) as progress_percentage
            FROM courses c
            LEFT JOIN categories cat ON c.category_id = cat.id
            LEFT JOIN user_enrollments ue ON c.id = ue.course_id AND ue.user_id = ?
            WHERE c.is_active = 1 AND c.total_enrollments > 150000
            ORDER BY c.total_enrollments DESC
        """, user_id)
        
        rows = cursor.fetchall()
        
        return [CourseResponse(
            id=row.id,
            title=row.title,
            description=row.description,
            thumbnail_url=row.thumbnail_url,
            category_id=row.category_id,
            category_name=row.category_name,
            instructor_name=row.instructor_name,
            duration_minutes=row.duration_minutes,
            level=row.level,
            price=float(row.price) if row.price else 0.0,
            is_free=bool(row.is_free),
            rating=float(row.rating) if row.rating else 0.0,
            total_ratings=row.total_ratings,
            total_enrollments=row.total_enrollments,
            is_enrolled=bool(row.is_enrolled),
            progress_percentage=float(row.progress_percentage),
            course_url=row.course_url
        ) for row in rows]
    finally:
        conn.close()

@app.get("/courses/{course_id}", response_model=CourseResponse)
async def get_course_detail(course_id: int, current_user: dict = Depends(verify_firebase_token)):
    conn = get_db_connection()
    cursor = conn.cursor()
    
    try:
        cursor.execute("SELECT id FROM users WHERE firebase_uid = ?", current_user["uid"])
        user_row = cursor.fetchone()
        user_id = user_row.id if user_row else None
        
        cursor.execute("""
            SELECT c.*, cat.name as category_name,
                   CASE WHEN ue.user_id IS NOT NULL THEN 1 ELSE 0 END as is_enrolled,
                   ISNULL(ue.progress_percentage, 0) as progress_percentage
            FROM courses c
            LEFT JOIN categories cat ON c.category_id = cat.id
            LEFT JOIN user_enrollments ue ON c.id = ue.course_id AND ue.user_id = ?
            WHERE c.id = ? AND c.is_active = 1
        """, user_id, course_id)
        
        row = cursor.fetchone()
        if not row:
            raise HTTPException(status_code=404, detail="Course not found")
        
        return CourseResponse(
            id=row.id,
            title=row.title,
            description=row.description,
            thumbnail_url=row.thumbnail_url,
            category_id=row.category_id,
            category_name=row.category_name,
            instructor_name=row.instructor_name,
            duration_minutes=row.duration_minutes,
            level=row.level,
            price=float(row.price) if row.price else 0.0,
            is_free=bool(row.is_free),
            rating=float(row.rating) if row.rating else 0.0,
            total_ratings=row.total_ratings,
            total_enrollments=row.total_enrollments,
            is_enrolled=bool(row.is_enrolled),
            progress_percentage=float(row.progress_percentage),
            course_url=row.course_url
        )
    finally:
        conn.close()

# Add this function to main.py after the verify_firebase_token function
async def get_or_create_user(current_user: dict):
    """Get user from database or create if doesn't exist"""
    conn = get_db_connection()
    cursor = conn.cursor()
    
    try:
        cursor.execute("SELECT id FROM users WHERE firebase_uid = ?", current_user["uid"])
        user_row = cursor.fetchone()
        
        if user_row:
            return user_row.id
        
        # Create user if doesn't exist
        email = current_user.get("email", f"{current_user['uid']}@unknown.com")
        display_name = current_user.get("name", "Unknown User")
        
        cursor.execute("""
            INSERT INTO users (firebase_uid, email, display_name, profile_picture_data)
            OUTPUT INSERTED.id VALUES (?, ?, ?, ?)
        """, current_user["uid"], email, display_name, None)
        
        new_user = cursor.fetchone()
        conn.commit()
        logger.info(f"Auto-created user {current_user['uid']} with ID {new_user.id}")
        
        return new_user.id
        
    except Exception as e:
        conn.rollback()
        logger.error(f"Failed to get or create user: {e}")
        raise HTTPException(status_code=500, detail="User setup failed")
    finally:
        conn.close()

# Then update your enroll_course function
@app.post("/courses/enroll")
async def enroll_course(
    request: EnrollRequest,
    current_user: dict = Depends(verify_firebase_token)
):
    conn = get_db_connection()
    cursor = conn.cursor()

    try:
        logger.info(f"Attempting to enroll user {current_user['uid']} in course {request.course_id}")
        
        # Use get_or_create_user instead of manual lookup
        user_id = await get_or_create_user(current_user)
        logger.info(f"User {user_id} found/created, proceeding with enrollment")
        
        cursor.execute(
            "SELECT id FROM user_enrollments WHERE user_id = ? AND course_id = ?",
            user_id, request.course_id
        )
        if cursor.fetchone():
            raise HTTPException(status_code=400, detail="Already enrolled in this course")
        
        cursor.execute("""
            INSERT INTO user_enrollments (user_id, course_id)
            VALUES (?, ?)
        """, user_id, request.course_id)
        
        cursor.execute("""
            UPDATE courses SET total_enrollments = total_enrollments + 1
            WHERE id = ?
        """, request.course_id)
        
        conn.commit()
        return {"message": "Successfully enrolled in course"}
    except Exception as e:
        conn.rollback()
        logger.error(f"Enrollment failed: {e}")
        raise HTTPException(status_code=500, detail="Enrollment failed")
    finally:
        conn.close()

# Also update other endpoints to use get_or_create_user
@app.get("/courses/{course_id}/lessons", response_model=List[LessonResponse])
async def get_course_lessons(course_id: int, current_user: dict = Depends(verify_firebase_token)):
    conn = get_db_connection()
    cursor = conn.cursor()
    
    try:
        user_id = await get_or_create_user(current_user)
        
        cursor.execute(
            "SELECT id FROM user_enrollments WHERE user_id = ? AND course_id = ?",
            user_id, course_id
        )
        if not cursor.fetchone():
            raise HTTPException(status_code=403, detail="Not enrolled in this course")
        
        cursor.execute("""
            SELECT cl.*, 
                   CASE WHEN ulp.is_completed IS NOT NULL THEN ulp.is_completed ELSE 0 END as is_watched,
                   ISNULL(ulp.watched_duration_seconds, 0) as watched_duration
            FROM course_lessons cl
            LEFT JOIN user_lesson_progress ulp ON cl.id = ulp.lesson_id AND ulp.user_id = ?
            WHERE cl.course_id = ? AND cl.is_active = 1
            ORDER BY cl.order_index
        """, user_id, course_id)
        
        rows = cursor.fetchall()
        
        return [LessonResponse(
            id=row.id,
            course_id=row.course_id,
            title=row.title,
            description=row.description,
            video_url=row.video_url,
            duration_seconds=row.duration_seconds,
            order_index=row.order_index,
            is_preview=bool(row.is_preview),
            is_watched=bool(row.is_watched),
            watched_duration=row.watched_duration
        ) for row in rows]
    finally:
        conn.close()

@app.post("/lessons/progress")
async def update_lesson_progress(
    request: UpdateProgressRequest,
    current_user: dict = Depends(verify_firebase_token)
):
    conn = get_db_connection()
    cursor = conn.cursor()
    
    try:
        cursor.execute("SELECT id FROM users WHERE firebase_uid = ?", current_user["uid"])
        user_row = cursor.fetchone()
        if not user_row:
            raise HTTPException(status_code=404, detail="User not found")
        user_id = user_row.id
        
        cursor.execute("""
            MERGE user_lesson_progress AS target
            USING (SELECT ? as user_id, ? as lesson_id, ? as watched_duration_seconds, ? as is_completed) AS source
            ON target.user_id = source.user_id AND target.lesson_id = source.lesson_id
            WHEN MATCHED THEN
                UPDATE SET watched_duration_seconds = source.watched_duration_seconds,
                          is_completed = source.is_completed,
                          completed_at = CASE WHEN source.is_completed = 1 THEN GETDATE() ELSE NULL END,
                          last_watched_at = GETDATE()
            WHEN NOT MATCHED THEN
                INSERT (user_id, lesson_id, watched_duration_seconds, is_completed, completed_at, last_watched_at)
                VALUES (source.user_id, source.lesson_id, source.watched_duration_seconds, 
                       source.is_completed, 
                       CASE WHEN source.is_completed = 1 THEN GETDATE() ELSE NULL END,
                       GETDATE());
        """, user_id, request.lesson_id, request.watched_duration_seconds, request.is_completed)
        
        cursor.execute("""
            UPDATE user_enrollments 
            SET progress_percentage = (
                SELECT CAST(COUNT(CASE WHEN ulp.is_completed = 1 THEN 1 END) AS FLOAT) / COUNT(*) * 100
                FROM course_lessons cl
                LEFT JOIN user_lesson_progress ulp ON cl.id = ulp.lesson_id AND ulp.user_id = ?
                WHERE cl.course_id = (SELECT course_id FROM course_lessons WHERE id = ?)
                AND cl.is_active = 1
            )
            WHERE user_id = ? AND course_id = (SELECT course_id FROM course_lessons WHERE id = ?)
        """, user_id, request.lesson_id, user_id, request.lesson_id)
        
        conn.commit()
        return {"message": "Progress updated successfully"}
    except Exception as e:
        conn.rollback()
        logger.error(f"Progress update failed: {e}")
        raise HTTPException(status_code=500, detail="Progress update failed")
    finally:
        conn.close()


# Fixed Quiz Endpoints for FastAPI

@app.get("/courses/{course_id}/quizzes", response_model=List[QuizResponse])
async def get_course_quizzes(course_id: int, current_user: dict = Depends(verify_firebase_token)):
    conn = get_db_connection()
    cursor = conn.cursor()
    
    try:
        cursor.execute("SELECT id FROM users WHERE firebase_uid = ?", current_user["uid"])
        user_row = cursor.fetchone()
        user_id = user_row.id if user_row else None
        
        # Fixed query - remove DISTINCT and handle NTEXT fields properly
        cursor.execute("""
            SELECT q.id, q.course_id, q.lesson_id, q.title, 
                   CAST(q.description AS NVARCHAR(MAX)) as description,
                   q.total_questions, q.time_limit_minutes, q.passing_score_percentage, 
                   q.attempts_allowed, q.created_at, q.is_active,
                   ISNULL(attempt_stats.user_attempts, 0) as user_attempts,
                   attempt_stats.best_score,
                   ISNULL(attempt_stats.is_passed, 0) as is_passed
            FROM quizzes q
            LEFT JOIN (
                SELECT quiz_id, 
                       COUNT(*) as user_attempts,
                       MAX(score_percentage) as best_score,
                       MAX(CAST(is_passed AS INT)) as is_passed
                FROM user_quiz_attempts 
                WHERE user_id = ?
                GROUP BY quiz_id
            ) attempt_stats ON q.id = attempt_stats.quiz_id
            WHERE q.course_id = ? AND q.is_active = 1
            ORDER BY q.created_at
        """, user_id, course_id)
        
        rows = cursor.fetchall()
        
        return [QuizResponse(
            id=row.id,
            course_id=row.course_id,
            lesson_id=row.lesson_id,
            title=row.title,
            description=row.description,
            total_questions=row.total_questions,
            time_limit_minutes=row.time_limit_minutes,
            passing_score_percentage=float(row.passing_score_percentage),
            attempts_allowed=row.attempts_allowed,
            user_attempts=row.user_attempts or 0,
            best_score=float(row.best_score) if row.best_score else None,
            is_passed=bool(row.is_passed) if row.is_passed else False
        ) for row in rows]
    finally:
        conn.close()

@app.get("/quizzes/{quiz_id}/questions", response_model=List[QuestionResponse])
async def get_quiz_questions(quiz_id: int, current_user: dict = Depends(verify_firebase_token)):
    conn = get_db_connection()
    cursor = conn.cursor()
    
    try:
        cursor.execute("SELECT id FROM users WHERE firebase_uid = ?", current_user["uid"])
        user_row = cursor.fetchone()
        if not user_row:
            raise HTTPException(status_code=404, detail="User not found")
        user_id = user_row.id
        
        # Check if user has access to this quiz
        cursor.execute("""
            SELECT ue.id FROM user_enrollments ue
            JOIN quizzes q ON ue.course_id = q.course_id
            WHERE q.id = ? AND ue.user_id = ?
        """, quiz_id, user_id)
        
        if not cursor.fetchone():
            raise HTTPException(status_code=403, detail="Access denied")
        
        # Get questions with options - cast NTEXT to NVARCHAR(MAX)
        cursor.execute("""
            SELECT qq.id, qq.quiz_id, 
                   CAST(qq.question_text AS NVARCHAR(MAX)) as question_text,
                   qq.question_type, qq.points, qq.order_index,
                   qao.id as option_id, 
                   CAST(qao.option_text AS NVARCHAR(MAX)) as option_text, 
                   qao.order_index as option_order
            FROM quiz_questions qq
            LEFT JOIN quiz_answer_options qao ON qq.id = qao.question_id
            WHERE qq.quiz_id = ? AND qq.is_active = 1
            ORDER BY qq.order_index, qao.order_index
        """, quiz_id)
        
        rows = cursor.fetchall()
        
        questions_dict = {}
        for row in rows:
            if row.id not in questions_dict:
                questions_dict[row.id] = {
                    "id": row.id,
                    "question_text": row.question_text,
                    "question_type": row.question_type,
                    "points": row.points,
                    "order_index": row.order_index,
                    "options": []
                }
            
            if row.option_id:
                questions_dict[row.id]["options"].append({
                    "id": row.option_id,
                    "text": row.option_text,
                    "order_index": row.option_order
                })
        
        return [QuestionResponse(**question) for question in questions_dict.values()]
    finally:
        conn.close()

@app.post("/quizzes/submit")
async def submit_quiz(
    request: SubmitQuizRequest,
    current_user: dict = Depends(verify_firebase_token)
):
    conn = get_db_connection()
    cursor = conn.cursor()
    
    try:
        cursor.execute("SELECT id FROM users WHERE firebase_uid = ?", current_user["uid"])
        user_row = cursor.fetchone()
        if not user_row:
            raise HTTPException(status_code=404, detail="User not found")
        user_id = user_row.id
        
        # Get quiz details
        cursor.execute("SELECT * FROM quizzes WHERE id = ?", request.quiz_id)
        quiz = cursor.fetchone()
        if not quiz:
            raise HTTPException(status_code=404, detail="Quiz not found")
        
        # Check attempts
        cursor.execute(
            "SELECT COUNT(*) as attempts FROM user_quiz_attempts WHERE user_id = ? AND quiz_id = ?",
            user_id, request.quiz_id
        )
        attempts = cursor.fetchone().attempts
        
        if attempts >= quiz.attempts_allowed:
            raise HTTPException(status_code=400, detail="Maximum attempts reached")
        
        # Create new attempt
        cursor.execute("""
            INSERT INTO user_quiz_attempts 
            (user_id, quiz_id, attempt_number, total_questions, time_taken_seconds)
            OUTPUT INSERTED.id
            VALUES (?, ?, ?, ?, ?)
        """, user_id, request.quiz_id, attempts + 1, quiz.total_questions, request.time_taken_seconds)
        
        attempt_id = cursor.fetchone().id
        
        # Process answers
        correct_answers = 0
        total_points = 0
        earned_points = 0
        
        for answer in request.answers:
            question_id = answer["question_id"]
            selected_option_id = answer.get("selected_option_id")
            answer_text = answer.get("answer_text")
            
            # Get question details
            cursor.execute("SELECT * FROM quiz_questions WHERE id = ?", question_id)
            question = cursor.fetchone()
            if not question:
                continue
            
            total_points += question.points
            is_correct = False
            points_earned = 0
            
            # Check if answer is correct
            if selected_option_id:
                cursor.execute(
                    "SELECT is_correct FROM quiz_answer_options WHERE id = ?",
                    selected_option_id
                )
                option = cursor.fetchone()
                if option and option.is_correct:
                    is_correct = True
                    correct_answers += 1
                    points_earned = question.points
                    earned_points += points_earned
            
            # Save user answer
            cursor.execute("""
                INSERT INTO user_quiz_answers 
                (attempt_id, question_id, selected_option_id, answer_text, is_correct, points_earned)
                VALUES (?, ?, ?, ?, ?, ?)
            """, attempt_id, question_id, selected_option_id, answer_text, is_correct, points_earned)
        
        # Calculate final score
        score_percentage = (earned_points / total_points * 100) if total_points > 0 else 0
        is_passed = score_percentage >= quiz.passing_score_percentage
        
        # Update attempt with final results
        cursor.execute("""
            UPDATE user_quiz_attempts 
            SET score_percentage = ?, correct_answers = ?, completed_at = GETDATE(), is_passed = ?
            WHERE id = ?
        """, score_percentage, correct_answers, is_passed, attempt_id)
        
        conn.commit()
        
        return {
            "attempt_id": attempt_id,
            "score_percentage": score_percentage,
            "correct_answers": correct_answers,
            "total_questions": quiz.total_questions,
            "is_passed": is_passed,
            "passing_score": quiz.passing_score_percentage
        }
    except Exception as e:
        conn.rollback()
        logger.error(f"Quiz submission failed: {e}")
        raise HTTPException(status_code=500, detail="Quiz submission failed")
    finally:
        conn.close()

@app.get("/user/enrollments", response_model=List[CourseResponse])
async def get_user_enrollments(current_user: dict = Depends(verify_firebase_token)):
    conn = get_db_connection()
    cursor = conn.cursor()
    
    try:
        cursor.execute("SELECT id FROM users WHERE firebase_uid = ?", current_user["uid"])
        user_row = cursor.fetchone()
        if not user_row:
            raise HTTPException(status_code=404, detail="User not found")
        user_id = user_row.id
        
        cursor.execute("""
            SELECT c.*, cat.name as category_name, ue.progress_percentage, ue.enrolled_at
            FROM user_enrollments ue
            JOIN courses c ON ue.course_id = c.id
            LEFT JOIN categories cat ON c.category_id = cat.id
            WHERE ue.user_id = ? AND ue.is_active = 1 AND c.is_active = 1
            ORDER BY ue.enrolled_at DESC
        """, user_id)
        
        rows = cursor.fetchall()
        
        return [CourseResponse(
            id=row.id,
            title=row.title,
            description=row.description,
            thumbnail_url=row.thumbnail_url,
            category_id=row.category_id,
            category_name=row.category_name,
            instructor_name=row.instructor_name,
            duration_minutes=row.duration_minutes,
            level=row.level,
            price=float(row.price) if row.price else 0.0,
            is_free=bool(row.is_free),
            rating=float(row.rating) if row.rating else 0.0,
            total_ratings=row.total_ratings,
            total_enrollments=row.total_enrollments,
            is_enrolled=True,
            progress_percentage=float(row.progress_percentage),
            course_url=row.course_url
        ) for row in rows]
    finally:
        conn.close()

@app.get("/user/quiz-attempts/{quiz_id}")
async def get_user_quiz_attempts(quiz_id: int, current_user: dict = Depends(verify_firebase_token)):
    conn = get_db_connection()
    cursor = conn.cursor()
    
    try:
        cursor.execute("SELECT id FROM users WHERE firebase_uid = ?", current_user["uid"])
        user_row = cursor.fetchone()
        if not user_row:
            raise HTTPException(status_code=404, detail="User not found")
        user_id = user_row.id
        
        cursor.execute("""
            SELECT * FROM user_quiz_attempts 
            WHERE user_id = ? AND quiz_id = ?
            ORDER BY attempt_number DESC
        """, user_id, quiz_id)
        
        rows = cursor.fetchall()
        
        return [{
            "id": row.id,
            "attempt_number": row.attempt_number,
            "score_percentage": float(row.score_percentage) if row.score_percentage else 0,
            "correct_answers": row.correct_answers,
            "total_questions": row.total_questions,
            "time_taken_seconds": row.time_taken_seconds,
            "started_at": row.started_at.isoformat() if row.started_at else None,
            "completed_at": row.completed_at.isoformat() if row.completed_at else None,
            "is_passed": bool(row.is_passed)
        } for row in rows]
    finally:
        conn.close()

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)