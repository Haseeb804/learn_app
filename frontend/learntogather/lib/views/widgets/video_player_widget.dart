// Add to pubspec.yaml:
// flutter_inappwebview: ^6.0.0
// youtube_player_iframe: ^5.2.2

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';

class InAppVideoPlayer extends StatefulWidget {
  final String? videoUrl;
  final String title;
  final Function(int seconds)? onProgressUpdate;
  final VoidCallback? onVideoComplete;

  const InAppVideoPlayer({
    Key? key,
    required this.videoUrl,
    required this.title,
    this.onProgressUpdate,
    this.onVideoComplete,
  }) : super(key: key);

  @override
  State<InAppVideoPlayer> createState() => _InAppVideoPlayerState();
}

class _InAppVideoPlayerState extends State<InAppVideoPlayer> {
  InAppWebViewController? _webViewController;
  YoutubePlayerController? _youtubeController;
  bool _hasError = false;
  bool _isLoading = true;
  String? _videoId;
  Timer? _progressTimer;
  int _currentSeconds = 0;
  bool _isPlayerReady = false;
  bool _isVideoPlaying = false;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  void _initializePlayer() {
    if (widget.videoUrl == null || widget.videoUrl!.isEmpty) {
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
      return;
    }

    _videoId = _extractVideoId(widget.videoUrl!);

    if (_videoId == null) {
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
      return;
    }

    // Use YouTube iframe player for web, custom WebView for mobile
    if (kIsWeb && _videoId != null) {
      _youtubeController = YoutubePlayerController.fromVideoId(
        videoId: _videoId!,
        autoPlay: false,
        params: const YoutubePlayerParams(
          showControls: true,
          showFullscreenButton: true,
          enableJavaScript: true,
        ),
      );
    }
  }

  String? _extractVideoId(String url) {
    try {
      String cleanUrl = url.trim();
      
      RegExp regExp = RegExp(
        r'(?:youtube\.com\/(?:[^\/]+\/.+\/|(?:v|e(?:mbed)?)\/|.*[?&]v=)|youtu\.be\/)([^"&?\/\s]{11})',
        caseSensitive: false,
      );
      
      Match? match = regExp.firstMatch(cleanUrl);
      if (match != null && match.group(1) != null) {
        return match.group(1);
      }
      
      Uri? uri = Uri.tryParse(cleanUrl);
      if (uri != null) {
        if (uri.host.contains('youtube.com') || uri.host.contains('www.youtube.com')) {
          return uri.queryParameters['v'];
        } else if (uri.host.contains('youtu.be')) {
          String path = uri.path;
          if (path.startsWith('/')) {
            path = path.substring(1);
          }
          return path.isNotEmpty ? path : null;
        }
      }
      
      return null;
    } catch (e) {
      print('Error extracting video ID: $e');
      return null;
    }
  }

  void _startProgressTracking() {
    _progressTimer?.cancel();
    _progressTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted && _isVideoPlaying) {
        _currentSeconds++;
        if (widget.onProgressUpdate != null) {
          widget.onProgressUpdate!(_currentSeconds);
        }
      }
    });
  }

  void _stopProgressTracking() {
    _progressTimer?.cancel();
    _progressTimer = null;
  }

  String _buildHtmlContent() {
    return '''
    <!DOCTYPE html>
    <html>
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=5.0, user-scalable=yes">
        <meta name="apple-mobile-web-app-capable" content="yes">
        <meta name="apple-mobile-web-app-status-bar-style" content="black-translucent">
        <title>Video Player</title>
        <style>
            * { 
                margin: 0; 
                padding: 0; 
                box-sizing: border-box; 
            }
            
            html, body { 
                height: 100%;
                width: 100%;
                overflow: hidden;
                background: #000;
                font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Arial, sans-serif;
            }
            
            .video-container {
                position: relative;
                width: 100%;
                height: 100%;
                background: #000;
                display: flex;
                align-items: center;
                justify-content: center;
            }
            
            .video-wrapper {
                position: relative;
                width: 100%;
                height: 100%;
                max-width: 100%;
                max-height: 100%;
            }
            
            #player {
                width: 100%;
                height: 100%;
                border: none;
                background: #000;
            }
            
            .loading-overlay {
                position: absolute;
                top: 0;
                left: 0;
                width: 100%;
                height: 100%;
                background: rgba(0, 0, 0, 0.8);
                display: flex;
                flex-direction: column;
                align-items: center;
                justify-content: center;
                z-index: 1000;
                color: white;
                font-size: 16px;
            }
            
            .spinner {
                border: 3px solid #333;
                border-top: 3px solid #ff0000;
                border-radius: 50%;
                width: 40px;
                height: 40px;
                animation: spin 1s linear infinite;
                margin-bottom: 15px;
            }
            
            @keyframes spin {
                0% { transform: rotate(0deg); }
                100% { transform: rotate(360deg); }
            }
            
            .error-message {
                color: #ff6b6b;
                text-align: center;
                padding: 20px;
            }
            
            .retry-button {
                background: #ff0000;
                color: white;
                border: none;
                padding: 10px 20px;
                border-radius: 5px;
                cursor: pointer;
                margin-top: 10px;
                font-size: 14px;
            }
            
            .retry-button:hover {
                background: #cc0000;
            }
        </style>
    </head>
    <body>
        <div class="video-container">
            <div class="loading-overlay" id="loading">
                <div class="spinner"></div>
                <div>Loading video...</div>
            </div>
            <div class="video-wrapper">
                <div id="player"></div>
            </div>
        </div>
        
        <script>
            console.log('Initializing YouTube Player for video ID: $_videoId');
            
            // Global variables
            let player;
            let isPlayerReady = false;
            let isPlaying = false;
            let progressInterval;
            let retryCount = 0;
            const maxRetries = 3;
            
            // Load YouTube IFrame API
            function loadYouTubeAPI() {
                if (window.YT && window.YT.Player) {
                    initializePlayer();
                    return;
                }
                
                const tag = document.createElement('script');
                tag.src = 'https://www.youtube.com/iframe_api';
                tag.onerror = function() {
                    console.error('Failed to load YouTube IFrame API');
                    showError('Failed to load video player');
                };
                
                const firstScriptTag = document.getElementsByTagName('script')[0];
                firstScriptTag.parentNode.insertBefore(tag, firstScriptTag);
            }
            
            // YouTube API ready callback
            window.onYouTubeIframeAPIReady = function() {
                console.log('YouTube IFrame API loaded');
                initializePlayer();
            };
            
            function initializePlayer() {
                try {
                    player = new YT.Player('player', {
                        height: '100%',
                        width: '100%',
                        videoId: '$_videoId',
                        playerVars: {
                            'playsinline': 1,
                            'autoplay': 0,
                            'controls': 1,
                            'modestbranding': 1,
                            'rel': 0,
                            'showinfo': 0,
                            'iv_load_policy': 3,
                            'fs': 1,
                            'enablejsapi': 1,
                            'origin': window.location.origin,
                            'widget_referrer': window.location.origin
                        },
                        events: {
                            'onReady': onPlayerReady,
                            'onStateChange': onPlayerStateChange,
                            'onError': onPlayerError
                        }
                    });
                } catch (error) {
                    console.error('Error initializing player:', error);
                    showError('Error initializing video player');
                }
            }
            
            function onPlayerReady(event) {
                console.log('YouTube player ready');
                isPlayerReady = true;
                hideLoading();
                
                // Notify Flutter
                notifyFlutter('onPlayerReady');
                
                // Set up progress tracking
                startProgressTracking();
                
                // Try to improve video quality
                try {
                    const availableQualities = player.getAvailableQualityLevels();
                    console.log('Available qualities:', availableQualities);
                    
                    if (availableQualities.length > 0) {
                        // Set to highest available quality or 'hd720' if available
                        const preferredQuality = availableQualities.includes('hd720') ? 'hd720' : availableQualities[0];
                        player.setPlaybackQuality(preferredQuality);
                        console.log('Set quality to:', preferredQuality);
                    }
                } catch (e) {
                    console.warn('Could not set video quality:', e);
                }
            }
            
            function onPlayerStateChange(event) {
                const state = event.data;
                console.log('Player state changed:', state);
                
                switch (state) {
                    case YT.PlayerState.UNSTARTED:
                        console.log('Video unstarted');
                        break;
                    case YT.PlayerState.ENDED:
                        console.log('Video ended');
                        isPlaying = false;
                        stopProgressTracking();
                        notifyFlutter('onVideoComplete');
                        break;
                    case YT.PlayerState.PLAYING:
                        console.log('Video playing');
                        isPlaying = true;
                        hideLoading();
                        notifyFlutter('onVideoPlay');
                        startProgressTracking();
                        break;
                    case YT.PlayerState.PAUSED:
                        console.log('Video paused');
                        isPlaying = false;
                        notifyFlutter('onVideoPause');
                        break;
                    case YT.PlayerState.BUFFERING:
                        console.log('Video buffering');
                        break;
                    case YT.PlayerState.CUED:
                        console.log('Video cued');
                        hideLoading();
                        break;
                }
            }
            
            function onPlayerError(event) {
                const errorCode = event.data;
                console.error('YouTube player error:', errorCode);
                
                let errorMessage = 'Video playback error';
                switch (errorCode) {
                    case 2:
                        errorMessage = 'Invalid video ID';
                        break;
                    case 5:
                        errorMessage = 'HTML5 player error';
                        break;
                    case 100:
                        errorMessage = 'Video not found';
                        break;
                    case 101:
                    case 150:
                        errorMessage = 'Video not allowed in embedded players';
                        break;
                }
                
                showError(errorMessage);
                notifyFlutter('onPlayerError', errorCode);
                
                // Try to retry
                if (retryCount < maxRetries) {
                    setTimeout(() => {
                        retryCount++;
                        console.log('Retrying player initialization, attempt:', retryCount);
                        document.getElementById('player').innerHTML = '';
                        initializePlayer();
                    }, 2000);
                }
            }
            
            function startProgressTracking() {
                if (progressInterval) {
                    clearInterval(progressInterval);
                }
                
                progressInterval = setInterval(() => {
                    if (player && player.getCurrentTime && isPlayerReady && isPlaying) {
                        try {
                            const currentTime = Math.floor(player.getCurrentTime() || 0);
                            if (currentTime > 0) {
                                notifyFlutter('onProgressUpdate', currentTime);
                            }
                        } catch (error) {
                            console.warn('Error getting current time:', error);
                        }
                    }
                }, 1000);
            }
            
            function stopProgressTracking() {
                if (progressInterval) {
                    clearInterval(progressInterval);
                    progressInterval = null;
                }
            }
            
            function hideLoading() {
                const loadingElement = document.getElementById('loading');
                if (loadingElement) {
                    loadingElement.style.display = 'none';
                }
            }
            
            function showError(message) {
                const loadingElement = document.getElementById('loading');
                if (loadingElement) {
                    loadingElement.innerHTML = '<div class="error-message">' + message + '<br><button class="retry-button" onclick="retryLoad()">Retry</button></div>';
                }
            }
            
            function retryLoad() {
                retryCount = 0;
                document.getElementById('loading').innerHTML = '<div class="spinner"></div><div>Loading video...</div>';
                document.getElementById('loading').style.display = 'flex';
                loadYouTubeAPI();
            }
            
            function notifyFlutter(handlerName, data = null) {
                try {
                    if (window.flutter_inappwebview && window.flutter_inappwebview.callHandler) {
                        if (data !== null) {
                            window.flutter_inappwebview.callHandler(handlerName, data);
                        } else {
                            window.flutter_inappwebview.callHandler(handlerName);
                        }
                    } else {
                        console.warn('Flutter handler not available for:', handlerName);
                    }
                } catch (error) {
                    console.error('Error notifying Flutter:', error);
                }
            }
            
            // Handle page visibility changes
            document.addEventListener('visibilitychange', () => {
                if (document.visibilityState === 'visible' && isPlaying) {
                    startProgressTracking();
                } else if (document.visibilityState === 'hidden') {
                    // Don't stop tracking, just log
                    console.log('Page hidden');
                }
            });
            
            // Prevent context menu
            document.addEventListener('contextmenu', (e) => {
                e.preventDefault();
            });
            
            // Handle orientation changes
            window.addEventListener('orientationchange', () => {
                setTimeout(() => {
                    if (player && player.getIframe) {
                        const iframe = player.getIframe();
                        if (iframe) {
                            iframe.style.width = '100%';
                            iframe.style.height = '100%';
                        }
                    }
                }, 500);
            });
            
            // Initialize when DOM is ready
            if (document.readyState === 'loading') {
                document.addEventListener('DOMContentLoaded', loadYouTubeAPI);
            } else {
                loadYouTubeAPI();
            }
            
            console.log('Video player script loaded for video ID: $_videoId');
        </script>
    </body>
    </html>
    ''';
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return _buildErrorWidget();
    }

    return Container(
      decoration: const BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Stack(
            children: [
              // Use YouTube Player for web, WebView for mobile
              if (kIsWeb && _youtubeController != null)
                YoutubePlayer(
                  controller: _youtubeController!,
                )
              else
                InAppWebView(
                  initialData: InAppWebViewInitialData(
                    data: _buildHtmlContent(),
                    mimeType: "text/html",
                    encoding: "utf8",
                  ),
                  initialSettings: InAppWebViewSettings(
                    // Core settings
                    javaScriptEnabled: true,
                    domStorageEnabled: true,
                    databaseEnabled: true,
                    
                    // Media settings
                    mediaPlaybackRequiresUserGesture: false,
                    allowsInlineMediaPlayback: true,
                    allowsPictureInPictureMediaPlayback: true,
                    
                    // Performance settings
                    cacheEnabled: true,
                    clearCache: false,
                    
                    // UI settings
                    supportZoom: false,
                    displayZoomControls: false,
                    builtInZoomControls: false,
                    
                    // Security settings
                    mixedContentMode: MixedContentMode.MIXED_CONTENT_ALWAYS_ALLOW,
                    
                    // WebView settings
                    transparentBackground: true,
                    useShouldOverrideUrlLoading: false,
                    useOnLoadResource: true,
                    
                    // Android specific
                    useHybridComposition: true,
                    hardwareAcceleration: true,
                    
                    // Disable scrolling
                    disableHorizontalScroll: true,
                    disableVerticalScroll: true,
                  ),
                  onWebViewCreated: (controller) {
                    _webViewController = controller;
                    print('WebView created successfully');
                    _addJavaScriptHandlers(controller);
                  },
                  onLoadStart: (controller, url) {
                    print('WebView load started: $url');
                    if (mounted) {
                      setState(() {
                        _isLoading = true;
                      });
                    }
                  },
                  onLoadStop: (controller, url) {
                    print('WebView load stopped: $url');
                    if (mounted) {
                      setState(() {
                        _isLoading = false;
                      });
                    }
                  },
                  onProgressChanged: (controller, progress) {
                    print('WebView progress: $progress%');
                    if (progress == 100 && mounted) {
                      setState(() {
                        _isLoading = false;
                      });
                    }
                  },
                  onConsoleMessage: (controller, consoleMessage) {
                    print('WebView Console [${consoleMessage.messageLevel}]: ${consoleMessage.message}');
                  },
                  onReceivedError: (controller, request, error) {
                    print('WebView Error: ${error.description}');
                    if (mounted) {
                      setState(() {
                        _hasError = true;
                        _isLoading = false;
                      });
                    }
                  },
                  onReceivedHttpError: (controller, request, errorResponse) {
                    print('WebView HTTP Error: ${errorResponse.statusCode}');
                  },
                ),

              // Loading overlay
              if (_isLoading && !_isPlayerReady)
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                          strokeWidth: 3,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Loading video...',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _addJavaScriptHandlers(InAppWebViewController controller) {
    // Player ready handler
    controller.addJavaScriptHandler(
      handlerName: 'onPlayerReady',
      callback: (args) {
        print('🎥 Player ready callback received');
        if (mounted) {
          setState(() {
            _isLoading = false;
            _isPlayerReady = true;
          });
        }
      },
    );

    // Video play handler
    controller.addJavaScriptHandler(
      handlerName: 'onVideoPlay',
      callback: (args) {
        print('▶️ Video play callback received');
        _isVideoPlaying = true;
        _startProgressTracking();
      },
    );

    // Video pause handler
    controller.addJavaScriptHandler(
      handlerName: 'onVideoPause',
      callback: (args) {
        print('⏸️ Video pause callback received');
        _isVideoPlaying = false;
        _stopProgressTracking();
      },
    );

    // Video complete handler
    controller.addJavaScriptHandler(
      handlerName: 'onVideoComplete',
      callback: (args) {
        print('✅ Video complete callback received');
        _isVideoPlaying = false;
        _stopProgressTracking();
        if (widget.onVideoComplete != null) {
          widget.onVideoComplete!();
        }
      },
    );

    // Progress update handler
    controller.addJavaScriptHandler(
      handlerName: 'onProgressUpdate',
      callback: (args) {
        if (args.isNotEmpty && widget.onProgressUpdate != null) {
          int seconds = args[0] is int ? args[0] : int.tryParse(args[0].toString()) ?? 0;
          if (seconds > 0) {
            widget.onProgressUpdate!(seconds);
          }
        }
      },
    );

    // Player error handler
    controller.addJavaScriptHandler(
      handlerName: 'onPlayerError',
      callback: (args) {
        print('❌ Player error callback received: $args');
        if (mounted) {
          setState(() {
            _hasError = true;
            _isLoading = false;
          });
        }
      },
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.red[400],
              size: 48,
            ),
            const SizedBox(height: 16),
            const Text(
              'Unable to load video',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please check your internet connection',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            if (widget.videoUrl != null) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  'Video ID: $_videoId',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _hasError = false;
                  _isLoading = true;
                  _isPlayerReady = false;
                });
                _initializePlayer();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _stopProgressTracking();
    _youtubeController?.close();
    super.dispose();
  }
}