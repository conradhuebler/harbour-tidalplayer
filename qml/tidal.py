# This Python file uses the following encoding: utf-8

import sys
import os
import base64
import hashlib
import secrets
import urllib.parse
(major, minor, micro, release, serial) = sys.version_info
sys.path.append("/usr/share/harbour-tidalplayer/lib/python" + str(major) + "." + str(minor) + "/site-packages/");

sys.path.append('/usr/share/harbour-tidalplayer/python/')
import socket
import requests
import json
import tidalapi
import pyotherside

# Debug function for controlled logging synchronized with QML debug levels
def debug_log(message, level=1, force=False):
    """
    Log debug messages with level control synchronized with QML
    level 1: Normal debug (QML debugLevel >= 1)
    level 2: Informative debug (QML debugLevel >= 2) 
    level 3: Verbose debug (QML debugLevel >= 3)
    force: Always log regardless of level (for critical errors)
    """
    import pyotherside
    try:
        # Use different pyotherside signals based on debug level
        # This allows QML to filter messages according to its debugLevel setting
        if force or level == 1:
            # Level 1 and force: Send as 'pythonDebugNormal' (QML shows when debugLevel >= 1)
            pyotherside.send('pythonDebugNormal', f"PYTHON: {message}")
        elif level == 2:
            # Level 2: Send as 'pythonDebugInfo' (QML shows when debugLevel >= 2)
            pyotherside.send('pythonDebugInfo', f"PYTHON: {message}")
        elif level == 3:
            # Level 3: Send as 'pythonDebugVerbose' (QML shows when debugLevel >= 3)
            pyotherside.send('pythonDebugVerbose', f"PYTHON: {message}")
        else:
            # Fallback for any other levels
            pyotherside.send('pythonDebugNormal', f"PYTHON: {message}")
    except:
        # Fallback to console if pyotherside fails
        print(f"PYTHON: {message}")

# Enhanced import with error handling and debug info
debug_log("Starting TidalAPI Python backend initialization", level=1)
debug_log(f"Python version: {sys.version}", level=2)
debug_log(f"Python path: {sys.path[:3]}...", level=2)

# Add custom Python path
python_path = '/usr/share/harbour-tidalplayer/python/'
if python_path not in sys.path:
    sys.path.append(python_path)
    debug_log(f"Added Python path: {python_path}", level=2)

# Check if path exists
if os.path.exists(python_path):
    debug_log(f"Python path verified: {python_path}", level=2)
    if os.path.exists(os.path.join(python_path, 'tidalapi')):
        debug_log("TidalAPI package found in Python path", level=2)
    else:
        debug_log("WARNING: TidalAPI package not found in Python path", level=1, force=True)
else:
    debug_log(f"WARNING: Python path does not exist: {python_path}", level=1, force=True)

# Import modules with detailed error handling
modules_to_import = [
    ('socket', 'socket'),
    ('requests', 'requests'),
    ('json', 'json', ),
    ('typing_extensions', 'typing_extensions'),
    ('dateutil', 'dateutil'),
    ('isodate', 'isodate'),
    ('tidalapi', 'tidalapi (main)'),
    ('pyotherside', 'pyotherside', )
]

debug_log("Importing standard modules...", level=2)
for module_name, display_name in modules_to_import:
    try:
        module = __import__(module_name)
        if hasattr(module, '__version__'):
            debug_log(f"✓ Imported {display_name} v{module.__version__}", level=2)
        else:
            debug_log(f"✓ Imported {display_name}", level=2)
        globals()[module_name] = module
    except ImportError as e:
        debug_log(f"✗ Failed to import {display_name}: {str(e)}", level=1, force=True)
        raise
    except Exception as e:
        debug_log(f"✗ Error importing {display_name}: {str(e)}", level=1, force=True)
        raise

# Import TidalAPI submodules with error handling
debug_log("Importing TidalAPI submodules...", level=2)
tidalapi_submodules = [
    ('tidalapi.page', ['PageItem', 'PageLink']),
    ('tidalapi.mix', ['Mix']),
    ('tidalapi.media', ['Quality']),
    ('requests.exceptions', ['HTTPError', 'RequestException'])
]

for module_path, classes in tidalapi_submodules:
    try:
        module = __import__(module_path, fromlist=classes)
        for class_name in classes:
            if hasattr(module, class_name):
                globals()[class_name] = getattr(module, class_name)
                debug_log(f"✓ Imported {module_path}.{class_name}", level=3)
            else:
                debug_log(f"✗ Class {class_name} not found in {module_path}", level=1, force=True)
        debug_log(f"✓ Imported {module_path}", level=2)
    except ImportError as e:
        debug_log(f"✗ Failed to import {module_path}: {str(e)}", level=1, force=True)
        raise
    except Exception as e:
        debug_log(f"✗ Error importing {module_path}: {str(e)}", level=1, force=True)
        raise

debug_log("All modules imported successfully", level=1)

# PKCE (Proof Key for Code Exchange) helper functions for OAuth 2.1 
def generate_pkce_pair():
    """
    Generate PKCE code verifier and challenge according to RFC 7636
    Returns: (code_verifier, code_challenge)
    """
    # Generate cryptographically random 32-byte code verifier
    code_verifier = base64.urlsafe_b64encode(secrets.token_bytes(32)).decode('utf-8').rstrip('=')
    
    # Create SHA256 challenge from verifier
    challenge_bytes = hashlib.sha256(code_verifier.encode()).digest()
    code_challenge = base64.urlsafe_b64encode(challenge_bytes).decode('utf-8').rstrip('=')
    
    debug_log(f"Generated PKCE pair - verifier length: {len(code_verifier)}, challenge length: {len(code_challenge)}", level=2)
    return code_verifier, code_challenge

def build_authorization_url(client_id, redirect_uri, code_challenge, state, scopes="r_usr"):
    """
    Build TIDAL OAuth 2.1 authorization URL with PKCE
    """
    params = {
        'response_type': 'code',
        'client_id': client_id,
        'redirect_uri': redirect_uri,
        'scope': scopes,
        'code_challenge_method': 'S256',
        'code_challenge': code_challenge,
        'state': state
    }
    
    base_url = "https://login.tidal.com/authorize"
    auth_url = f"{base_url}?{urllib.parse.urlencode(params)}"
    debug_log(f"Built authorization URL: {auth_url[:100]}...", level=2)
    return auth_url


class Tidal:
    def __init__(self):
        debug_log("Creating Tidal class instance", level=1)
        self.session = None
        self.config = None
        self.top_tracks = 20
        self.album_search = 20
        self.track_search = 20
        self.artist_search = 20
        
        # OAuth 2.1 Web Flow state
        self.oauth_state = None
        self.oauth_web_enabled = True  # Prefer new OAuth method
        
        # TIDAL OAuth 2.1 PKCE Configuration
        self.client_id = "6BDSRdpK9hqEBTgU"  # Official TIDAL PKCE client ID
        self.redirect_uri = "http://localhost:8080/callback"  # Localhost for testing

        debug_log("Tidal class initialized, sending loadingStarted signal", level=2)
        pyotherside.send('loadingStarted')

    def initialize(self, quality="HIGH"):
        debug_log(f"Initializing TidalAPI with quality: {quality}", level=1)
        
        try:
            # Enhanced quality selection with debug info
            quality_mapping = {
                "LOW": (Quality.low_96k, "96k"),
                "HIGH": (Quality.low_320k, "320k"), 
                "LOSSLESS": (Quality.high_lossless, "lossless"),
                "TEST": (Quality.low_96k, "96k test")
            }
            
            if quality in quality_mapping:
                selected_quality, quality_name = quality_mapping[quality]
                debug_log(f"Selected audio quality: {quality_name}", level=2)
            else:
                selected_quality = Quality.default
                debug_log(f"Unknown quality '{quality}', using default", level=1, force=True)
                quality_name = "default"

            # Check if tidalapi classes are available
            debug_log("Creating TidalAPI Config object...", level=2)
            
            if not hasattr(tidalapi, 'Config'):
                raise AttributeError("tidalapi.Config class not found")
            if not hasattr(tidalapi, 'VideoQuality'):
                raise AttributeError("tidalapi.VideoQuality class not found")
            if not hasattr(tidalapi, 'Session'):
                raise AttributeError("tidalapi.Session class not found")
                
            self.config = tidalapi.Config(
                quality=selected_quality, 
                video_quality=tidalapi.VideoQuality.low
            )
            debug_log(f"TidalAPI Config created successfully with {quality_name} audio quality", level=2)

            # Only create new session if none exists or session is invalid
            if not hasattr(self, 'session') or not self.session:
                debug_log("Creating new TidalAPI Session object...", level=2)
                self.session = tidalapi.Session(self.config)
                if self.session:
                    debug_log("New TidalAPI Session created successfully", level=1)
            else:
                debug_log("Reusing existing TidalAPI Session object", level=2)
                # Update existing session config
                if hasattr(self.session, 'config'):
                    self.session.config = self.config
                    debug_log("Updated existing session config", level=2)
                    
            if self.session:
                debug_log("TidalAPI Session ready", level=1)
                # Check session capabilities
                if hasattr(self.session, 'login_oauth_simple'):
                    debug_log("OAuth login method available", level=2)
                if hasattr(self.session, 'check_login'):
                    debug_log("Login check method available", level=2)
            else:
                debug_log("WARNING: TidalAPI Session creation returned None", level=1, force=True)
                
        except AttributeError as e:
            debug_log(f"CRITICAL: TidalAPI class missing: {str(e)}", level=1, force=True)
            debug_log("This indicates a TidalAPI installation problem", level=1, force=True)
            raise
        except Exception as e:
            debug_log(f"CRITICAL: Failed to initialize TidalAPI: {str(e)}", level=1, force=True)
            debug_log(f"Error type: {type(e).__name__}", level=1, force=True)
            raise

    def setconfig(self, top_tracks, album_search, track_search, artist_search):
        self.top_tracks = top_tracks
        self.album_search = album_search
        self.track_search = track_search
        self.artist_search = artist_search

    def login(self, token_type, access_token, refresh_token, expiry_time):
        try:
            if access_token == token_type:
                pyotherside.send("oauth_login_failed")
            else:
                if access_token == refresh_token:
                    debug_log("Getting new token via refresh", level=1)

                    try:
                        self.session.token_refresh(refresh_token)
                        self.session.load_oauth_session(token_type, self.session.access_token)

                        if self.session.check_login() is True:
                            debug_log(f"New token obtained (length: {len(self.session.access_token)} chars)", level=1)
                            # Send all token info including new expiry time
                            pyotherside.send("oauth_refresh", self.session.access_token, 
                                            self.session.refresh_token, self.session.expiry_time)
                            pyotherside.send("oauth_login_success")
                            debug_log("Login verification successful", level=1)
                        else:
                            pyotherside.send("printConsole", "Token refresh failed - login check unsuccessful")
                            pyotherside.send("oauth_login_failed")

                    except HTTPError as http_err:
                        if http_err.response.status_code == 401:
                            pyotherside.send("printConsole", "Token refresh failed - 401 Unauthorized")
                            pyotherside.send("oauth_login_failed")
                        else:
                            pyotherside.send("printConsole", f"HTTP error during token refresh: {http_err}")
                            pyotherside.send("oauth_login_failed")

                    except RequestException as req_err:
                        pyotherside.send("printConsole", f"Network error during token refresh: {req_err}")
                        pyotherside.send("oauth_login_failed")

                    except Exception as e:
                        pyotherside.send("printConsole", f"Unexpected error during token refresh: {e}")
                        pyotherside.send("oauth_login_failed")

                else:
                    pyotherside.send("printConsole", "Login with old token")

                    try:
                        self.session.load_oauth_session(token_type, access_token)

                        if self.session.check_login() == True:
                            pyotherside.send("oauth_login_success")
                            debug_log("Login verification successful", level=1)
                        else:
                            pyotherside.send("printConsole", "Login check failed with old token")
                            pyotherside.send("oauth_login_failed")

                    except HTTPError as http_err:
                        if http_err.response.status_code == 401:
                            pyotherside.send("printConsole", "Login failed - 401 Unauthorized, please re-authenticate")
                            pyotherside.send("oauth_login_failed")
                        else:
                            pyotherside.send("printConsole", f"HTTP error during login: {http_err}")
                            pyotherside.send("oauth_login_failed")

                    except RequestException as req_err:
                        pyotherside.send("printConsole", f"Network error during login: {req_err}")
                        pyotherside.send("oauth_login_failed")

                    except Exception as e:
                        pyotherside.send("printConsole", f"Unexpected error during login: {e}")
                        pyotherside.send("oauth_login_failed")

        except Exception as outer_e:
            # Fallback für alle anderen unerwarteten Fehler
            pyotherside.send("printConsole", f"Critical error in login function: {outer_e}")
            pyotherside.send("oauth_login_failed")

    def request_oauth(self):
        debug_log("Starting OAuth authentication process", level=1)
        
        try:
            # Check if session is available
            if not self.session:
                debug_log("CRITICAL: TidalAPI session is None, cannot proceed with OAuth", level=1, force=True)
                pyotherside.send("oauth_failed")
                return
                
            if not hasattr(self.session, 'login_oauth'):
                debug_log("CRITICAL: TidalAPI session missing login_oauth method", level=1, force=True)
                pyotherside.send("oauth_failed")
                return
                
            debug_log("Calling TidalAPI login_oauth()...", level=2)
            self.login, self.future = self.session.login_oauth()
            
            if not self.login:
                debug_log("CRITICAL: OAuth login object is None", level=1, force=True)
                pyotherside.send("oauth_failed")
                return
                
            if not hasattr(self.login, 'verification_uri_complete'):
                debug_log("CRITICAL: OAuth login missing verification_uri_complete", level=1, force=True)
                pyotherside.send("oauth_failed")
                return
                
            oauth_url = self.login.verification_uri_complete
            debug_log(f"OAuth URL obtained: {oauth_url[:50]}...", level=2)
            pyotherside.send("get_url", oauth_url)
            
            debug_log("Waiting for user OAuth completion...", level=1)
            
            if not self.future:
                debug_log("CRITICAL: OAuth future object is None", level=1, force=True)
                pyotherside.send("oauth_failed")
                return
                
            # Wait for OAuth completion
            self.future.result()
            
            # Check tokens
            if hasattr(self.session, 'access_token') and self.session.access_token:
                debug_log(f"OAuth completed, token received (length: {len(self.session.access_token)} chars)", level=1)
            else:
                debug_log("WARNING: OAuth completed but no access token received", level=1, force=True)
                
            # Verify login
            if self.session.check_login():
                debug_log("OAuth login verification successful", level=1)
                debug_log(f"Token type: {getattr(self.session, 'token_type', 'unknown')}", level=2)
                debug_log(f"Token expires: {getattr(self.session, 'expiry_time', 'unknown')}", level=2)
                
                pyotherside.send("get_token", 
                                self.session.token_type, 
                                self.session.access_token, 
                                self.session.refresh_token, 
                                self.session.expiry_time)
            else:
                debug_log("CRITICAL: OAuth login verification failed", level=1, force=True)
                pyotherside.send("oauth_failed")
                
        except HTTPError as e:
            debug_log(f"HTTP error during OAuth: {e} (Status: {getattr(e.response, 'status_code', 'unknown')})", level=1, force=True)
            pyotherside.send("oauth_failed")
        except Exception as e:
            debug_log(f"Unexpected error during OAuth: {str(e)} (Type: {type(e).__name__})", level=1, force=True)
            pyotherside.send("oauth_failed")
            
        pyotherside.send('loadingFinished')

    def request_oauth_web(self, scopes="r_usr"):
        """
        New TIDAL OAuth 2.1 Web Flow with PKCE (Proof Key for Code Exchange)
        More secure than device flow, better user experience
        """
        debug_log("Starting OAuth 2.1 Web Flow with PKCE", level=1)
        
        try:
            # Generate PKCE code verifier and challenge
            code_verifier, code_challenge = generate_pkce_pair()
            
            # Generate secure random state for CSRF protection
            state = base64.urlsafe_b64encode(secrets.token_bytes(32)).decode('utf-8').rstrip('=')
            
            # Store OAuth state for later verification
            self.oauth_state = {
                'code_verifier': code_verifier,
                'state': state,
                'redirect_uri': self.redirect_uri,
                'client_id': self.client_id,
                'scopes': scopes
            }
            
            debug_log(f"OAuth state stored - client_id: {self.client_id}, scopes: {scopes}", level=2)
            
            # Build authorization URL with PKCE parameters
            auth_url = build_authorization_url(
                client_id=self.client_id,
                redirect_uri=self.redirect_uri, 
                code_challenge=code_challenge,
                state=state,
                scopes=scopes
            )
            
            debug_log("Sending authorization URL to QML WebView", level=1)
            pyotherside.send("auth_url", auth_url)
            
        except Exception as e:
            debug_log(f"Error starting OAuth web flow: {str(e)}", level=1, force=True)
            pyotherside.send("oauth_failed", f"Failed to start OAuth: {str(e)}")

    def exchange_authorization_code(self, authorization_code, received_state):
        """
        Exchange authorization code for access/refresh tokens
        Part 2 of OAuth 2.1 Web Flow
        """
        debug_log(f"Starting token exchange with authorization code: {authorization_code[:10]}...", level=1)
        
        try:
            # Validate OAuth state
            if not self.oauth_state:
                debug_log("CRITICAL: No OAuth state found for token exchange", level=1, force=True)
                pyotherside.send("oauth_failed", "Invalid OAuth state")
                return
                
            if received_state != self.oauth_state['state']:
                debug_log("CRITICAL: State parameter mismatch - potential CSRF attack", level=1, force=True)
                pyotherside.send("oauth_failed", "Invalid state parameter")
                return
                
            # Prepare token exchange request
            token_data = {
                'grant_type': 'authorization_code',
                'client_id': self.oauth_state['client_id'],
                'code': authorization_code,
                'redirect_uri': self.oauth_state['redirect_uri'],
                'code_verifier': self.oauth_state['code_verifier']
            }
            
            debug_log("Exchanging authorization code for tokens...", level=2)
            
            # Exchange code for tokens
            response = requests.post(
                'https://auth.tidal.com/v1/oauth2/token',
                data=token_data,
                headers={'Content-Type': 'application/x-www-form-urlencoded'},
                timeout=30
            )
            
            if response.status_code == 200:
                tokens = response.json()
                debug_log(f"Token exchange successful - expires_in: {tokens.get('expires_in', 'unknown')}", level=1)
                
                # Initialize TidalAPI session with new tokens
                if self.session:
                    self.session.access_token = tokens['access_token']
                    self.session.refresh_token = tokens.get('refresh_token', '')
                    self.session.token_type = tokens.get('token_type', 'Bearer')
                    
                    # Calculate expiry time
                    expires_in = tokens.get('expires_in', 86400)  # Default 24 hours
                    import time
                    self.session.expiry_time = int(time.time() + expires_in)
                    
                    # Verify login
                    if self.session.check_login():
                        debug_log("OAuth 2.1 login successful", level=1)
                        pyotherside.send("get_token", 
                                        self.session.token_type, 
                                        self.session.access_token, 
                                        self.session.refresh_token, 
                                        self.session.expiry_time)
                    else:
                        debug_log("Token exchange successful but login verification failed", level=1, force=True)
                        pyotherside.send("oauth_failed", "Login verification failed")
                else:
                    debug_log("CRITICAL: No session available for token storage", level=1, force=True)
                    pyotherside.send("oauth_failed", "No session available")
                    
            else:
                error_msg = f"Token exchange failed: {response.status_code} - {response.text}"
                debug_log(error_msg, level=1, force=True)
                pyotherside.send("oauth_failed", error_msg)
                
        except requests.RequestException as e:
            error_msg = f"Network error during token exchange: {str(e)}"
            debug_log(error_msg, level=1, force=True)
            pyotherside.send("oauth_failed", error_msg)
        except Exception as e:
            error_msg = f"Unexpected error during token exchange: {str(e)}"
            debug_log(error_msg, level=1, force=True)
            pyotherside.send("oauth_failed", error_msg)
        finally:
            # Clear OAuth state after use
            self.oauth_state = None
            pyotherside.send('loadingFinished')

    def handle_track(self, track):
        try:
            return {
                "trackid": str(track.id),
                "title": str(track.name),
                "artist": str(track.artist.name),
                "artistid": str(track.artist.id),
                "album": str(track.album.name),
                "albumid": int(track.album.id),
                "duration": int(track.duration),
                "image": track.album.image(320) if hasattr(track.album, 'image') else "",
                "track_num" : track.track_num,
                "type": "track",
                "albumid": track.album.id
            }
        except AttributeError as e:
            print(f"Error handling track: {e}")
            return None

    def handle_artist(self, artist):
        try:
            artisti = {
                "artistid": str(artist.id),
                "name": str(artist.name),
                "image": artist.image(320) if hasattr(artist, 'image') else "image://theme/icon-m-media-artists",
                "type": "artist",
                "bio" : ""
            }
        except AttributeError as e:
            print(f"Error handling artist: {e}")
            return None
        try:
            bio = str(artist.get_bio())
        except HTTPError as e:
            if e.response.status_code == 404:
                print(f"Error fetching biography: {e}")
                return artisti
            return artisti
        except tidalapi.exceptions.ObjectNotFound as e:
            return artisti
        artisti["bio"] = bio
        return artisti

    def handle_album(self, album):
        try:
            return {
                "albumid": int(album.id),
                "title": str(album.name),
                "artist": str(album.artist.name),
                "artistid" : str(album.artist.id),
                "image": album.image(320) if hasattr(album, 'image') else "image://theme/icon-m-media-albums",
                "duration": int(album.duration) if hasattr(album, 'duration') else 0,
                "num_tracks": int(album.num_tracks),
                "year": int(album.year),
                "type": "album"
            }
        except AttributeError as e:
            print(f"Error handling album: {e}")
            return None

    def handle_video(self, video):
        try:
            return {
                "videoid": str(video.id),
                "title": str(video.name),
                "artist": str(video.artist.name),
                "artistid": str(video.artist.id),
                "album": str(video.album.name),
                "albumid": int(video.album.id),
                "duration": int(video.duration),
                "image": video.album.image(320) if hasattr(video.album, 'image') else "",
                "track_num" : video.track_num,
                "type": "video",
                "albumid": video.album.id
            }
        except AttributeError as e:
            print(f"Error handling video: {e}")
            return None

    def send_object(self, signal_name, data, data2=None):
        """Helper-Funktion zum Senden von Objekten"""
        try:
            if (data2 is None):
                pyotherside.send(signal_name, data)
            else:
                pyotherside.send(signal_name, data, data2)
        except Exception as e:
            print(f"Error sending object: {e}")

    def handle_playlist(self, playlist):
        """Handler für Playlist-Informationen"""
        try:
            return {
                "playlistid": str(playlist.id),
                "title": str(playlist.name),
                "image": playlist.image(320) if hasattr(playlist, 'image') else "image://theme/icon-m-media-playlists",
                "duration": int(playlist.duration) if hasattr(playlist, 'duration') else 0,
                "num_tracks": playlist.num_tracks if hasattr(playlist, 'num_tracks') else 0,
                "description": playlist.description if hasattr(playlist, 'description') else "",
                "type": "playlist"
            }
        except AttributeError as e:
            pyotherside.send("printConsole", f"Error handling playlist: {e}")
            print(f"Error handling playlist: {e}")
            return None

    def handle_mix(self, mix):
        """Handler für Mix-Informationen, nicht fertig, """
        try:
            default_image = "image://theme/icon-m-media-playlists"
            image = default_image
            # image will not work with current tidalapi version
            if hasattr(mix, 'images'):
                if hasattr(mix.images, 'small'):
                    image = str(mix.images.small)
            return {
                "mixid": str(mix.id),
                "title": str(mix.title),
                "image": image,
                "duration": int(mix.duration) if hasattr(mix, 'duration') else 0,
                "num_tracks": mix.num_tracks if hasattr(mix, 'num_tracks') else 0,
                "description": mix.sub_title if hasattr(mix, 'sub_title') else "",
                "type": "mix"
            } # rather try to return items.count as num_tracks
        except AttributeError as e:
            print(f"Error handling mix: {e}")
            pyotherside.send("printConsole", f"trouble loading mix: f{e}")
            return None

    def genericSearch(self, text):
        pyotherside.send('loadingStarted')
        result = self.session.search(text)

        # OLD: Individual signals (many bridge calls)
        # NEW: Batch processing for better performance
        search_results = {
            "tracks": [],
            "artists": [],
            "albums": [],
            "playlists": [],
            "videos": [],
            "mixes": []
        }

        # Batch process tracks
        if "tracks" in result:
            for track in result["tracks"]:
                if track_info := self.handle_track(track):
                    search_results["tracks"].append(track_info)
                    self.send_object("cacheTrack", track_info)

        # Batch process artists
        if "artists" in result:
            for artist in result["artists"]:
                if artist_info := self.handle_artist(artist):
                    search_results["artists"].append(artist_info)
                    self.send_object("cacheArtist", artist_info)

        # Batch process albums
        if "albums" in result:
            for album in result["albums"]:
                if album_info := self.handle_album(album):
                    search_results["albums"].append(album_info)
                    self.send_object("cacheAlbum", album_info)

        # Batch process playlists
        if "playlists" in result:
            for playlist in result["playlists"]:
                if playlist_info := self.handle_playlist(playlist):
                    search_results["playlists"].append(playlist_info)

        # Batch process videos
        if "videos" in result:
            for video in result["videos"]:
                if video_info := self.handle_video(video):
                    search_results["videos"].append(video_info)

        # Batch process mixes
        if "mixes" in result:
            for mix in result["mixes"]:
                if mix_info := self.handle_mix(mix):
                    search_results["mixes"].append(mix_info)

        # PERFORMANCE: Send all results in batches instead of individually
        if search_results["tracks"]:
            pyotherside.send("foundTracksBatch", search_results["tracks"])
        if search_results["artists"]:
            pyotherside.send("foundArtistsBatch", search_results["artists"])
        if search_results["albums"]:
            pyotherside.send("foundAlbumsBatch", search_results["albums"])
        if search_results["playlists"]:
            pyotherside.send("foundPlaylistsBatch", search_results["playlists"])
        if search_results["videos"]:
            pyotherside.send("foundVideosBatch", search_results["videos"])
        if search_results["mixes"]:
            pyotherside.send("foundMixesBatch", search_results["mixes"])

        pyotherside.send('loadingFinished')
        return result

    def getMixInfo(self, id):
        try:
            mix = self.session.mix(id)
            mix_info = self.handle_mix(mix)
            if mix_info:
                self.send_object("cacheMix", mix_info)
                return mix_info
            return None
        except Exception as e:
            self.send_object("error", {"message": str(e)})
            return None

    def getAlbumInfo(self, id):
        try:
            album = self.session.album(int(id))
            album_info = self.handle_album(album)
            if album_info:
                self.send_object("cacheAlbum", album_info)
                return album_info
            return None
        except Exception as e:
            self.send_object("error", {"message": str(e)})
            return None

    def getArtistInfo(self, id):
        try:
            artist = self.session.artist(int(id))
            artist_info = self.handle_artist(artist)
            if artist_info:
                self.send_object("cacheArtist", artist_info)
                return artist_info
            return None
        except Exception as e:
            self.send_object("error", {"message": str(e)})
            return None

    def getTrackInfo(self, id):
        try:
            track = self.session.track(int(id))
            track_info = self.handle_track(track)
            if track_info:
                self.send_object("cacheTrack", track_info)
                return track_info
            return None
        except Exception as e:
            self.send_object("error", {"message": str(e)})
            return None

    def getTrackUrl(self, id):
        try:
            track = self.session.track(int(id))
            url = track.get_url()
            track_info = self.handle_track(track)

            if track_info and url:
                self.send_object("playback_info", {
                    "track": track_info,
                    "url": url
                })
                return track_info
            return None
        except Exception as e:
            self.send_object("error", {"message": str(e)})
        return None

    def getMixTracks(self, id):
        pyotherside.send('loadingStarted')
        try:
            mix = self.session.mix(id)
            for track in mix.items():
                track_info = self.handle_track(track)
                if track_info:
                    pyotherside.send("cacheTrack", track_info)
                    pyotherside.send("mixTrackAdded",track_info)
            return mix # just for testing
        finally:
            pyotherside.send('loadingFinished')

    def playMix(self, id, autoPlay=False):
        try:
            pyotherside.send('loadingStarted')
            mix = self.session.mix(id)
            mix_info = self.handle_mix(mix)
            
            if mix_info:
                tracks = []
                for track in mix.items():
                    if track_info := self.handle_track(track):
                        pyotherside.send("cacheTrack", track_info)
                        tracks.append(track_info)
                
                # Send mix replacement signal (like playlist)
                self.send_object("mix_replace", {
                    "mix": mix_info,
                    "tracks": tracks
                })
                
                # Start playback if requested
                if autoPlay and tracks:
                    self.send_object("play_track", tracks[0])
                    
            pyotherside.send('loadingFinished')
        except Exception as e:
            self.send_object("error", {"message": str(e)})
            pyotherside.send('loadingFinished')

#  not sure if this method is used at all
    def playPlaylist(self, id):
        try:
            playlist = self.session.playlist(id)
            playlist_info = self.handle_playlist(playlist)

            if playlist_info:
                tracks = []
                for track in playlist.tracks():
                    if track_info := self.handle_track(track):
                        tracks.append(track_info)

                self.send_object("playlist_replace", {
                    "playlist": playlist_info,
                    "tracks": tracks
                })

                # Ersten Track zur Wiedergabe markieren
                if tracks:
                    self.send_object("play_track", tracks[0])

                return playlist_info
        except Exception as e:
            self.send_object("error", {"message": str(e)})
            return None

    def getAlbumTracks(self, id):
        album = self.session.album(int(id))
        for track in album.tracks():
            track_info = self.handle_track(track)
            if track_info:
                pyotherside.send("cacheTrack", track_info)
                pyotherside.send("albumTrackAdded",track_info)

    def playAlbumTracks(self, id, autoPlay=False):
        album = self.session.album(int(id))
        for track in album.tracks():
            track_info = self.handle_track(track)
            if track_info:
                pyotherside.send("cacheTrack", track_info)
                pyotherside.send("addTracktoPL", track_info['trackid'])
        pyotherside.send("fillFinished", autoPlay)

    def playAlbumfromTrack(self, id):
        for track in self.session.track(int(id)).album.tracks():
            track_info = self.handle_track(track)
            if track_info:
                pyotherside.send("cacheTrack", track_info)
                pyotherside.send("addTracktoPL", track_info['trackid'])
        pyotherside.send("fillFinished", False)

    def playArtistTracks(self, id, autoPlay=False):
        artist = self.session.artist(int(id))
        for track in artist.get_top_tracks(self.top_tracks):
            track_info = self.handle_track(track)
            if track_info:
                pyotherside.send("cacheTrack", track_info)
                pyotherside.send("addTracktoPL", track_info['trackid'])
        pyotherside.send("fillFinished", autoPlay)

    def playArtistRadio(self, id, autoPlay=False):
        artist = self.session.artist(int(id))
        for track in artist.get_radio():
            track_info = self.handle_track(track)
            if track_info:
                pyotherside.send("cacheTrack", track_info)
                pyotherside.send("addTracktoPL", track_info['trackid'])
        pyotherside.send("fillFinished", autoPlay)

    # this is kinda duplicate of getTopTracksofArtist
    #def getTopTracks(self, id, max):
    #    toptracks = self.session.artist(int(id)).get_top_tracks(max)
    #    for track in toptracks:
    #        track_info = self.handle_track(track)
    #        if track_info:
    #            pyotherside.send("cacheTrack", track_info)
    #            pyotherside.send("addTrack",
    #                track_info['trackid'],
    #                track_info['title'],
    #                track_info['album'],
    #                track_info['artist'],
    #                track_info['image'],
    #                track_info['duration'])
    
    def getArtistRadio(self, id): # -> Optional[List[Track]]:
        pyotherside.send('loadingStarted')
        tracks = self.session.artist(int(id)).get_radio()
        for ti in tracks:
            i = self.handle_track(ti)
            pyotherside.send("cacheTrack", i)
            pyotherside.send("RadioTrackofArtist", i)

        pyotherside.send('loadingFinished')
        return tracks  # just for testing
                
    def getPersonalPlaylists(self):
        pyotherside.send('loadingStarted')
        playlists = self.session.user.playlists()
        for i in playlists:
            playlist_info = self.handle_playlist(i)
            self.send_object("addPersonalPlaylist", playlist_info)
        pyotherside.send('loadingFinished')

    def playPlaylist(self, id, autoPlay=False):
        pyotherside.send('loadingStarted')
        playlist = self.session.playlist(id)
        first_track = playlist.tracks()[0]
        #pyotherside.send("insertTrack", first_track.id)
        pyotherside.send("printConsole", f" insert Track: {first_track.id}")

        for i, track in enumerate(playlist.tracks()):
            track_info = self.handle_track(track)
            if track_info:
                pyotherside.send("cacheTrack", track_info)
                pyotherside.send("addTracktoPL", track_info['trackid']) #maybe silent ?

            #if i == 0:

        # playlist = self.session.playlist(id)
        #playlist_info = self.handle_playlist(playlist)
        # #    pyotherside.send("fillStarted")

        pyotherside.send("fillFinished", autoPlay)
        pyotherside.send('loadingFinished')
        #return playlist_info

    def getPlaylistTracks(self, playlist_id):
        pyotherside.send('loadingStarted')
        try:
            playlist = self.session.playlist(playlist_id)

            for ti in playlist.tracks():
                i = self.handle_track(ti)
                pyotherside.send("cacheTrack", i)
                pyotherside.send('playlistTrackAdded',i)
            return playlist # just for testing

        finally:
            pyotherside.send('loadingFinished')

    def getAlbumsofArtist(self, id):
        pyotherside.send('loadingStarted')
        albums = self.session.artist(int(id)).get_albums()
        for ti in albums:
            i = self.handle_album(ti)
            pyotherside.send("cacheAlbum", i)
            pyotherside.send("AlbumofArtist", i)

        pyotherside.send('loadingFinished')

    def getTopTracksofArtist(self, id):
        pyotherside.send('loadingStarted')
        tracks = self.session.artist(int(id)).get_top_tracks(self.top_tracks)
        for ti in tracks:
            i = self.handle_track(ti)
            pyotherside.send("cacheTrack", i)
            pyotherside.send("TopTrackofArtist", i)

        pyotherside.send('loadingFinished')

    def getSimiliarArtist(self, id):
        pyotherside.send('loadingStarted')
        try:
            artists = self.session.artist(int(id)).get_similar()
            if artists:  # Wenn Artists zurückgegeben wurden
                for ti in artists:
                    i = self.handle_artist(ti)
                    #pyotherside.send("cacheArtist", i)
                    pyotherside.send("SimilarArtist", i)
            else:
                pyotherside.send("noSimilarArtists")  # Signal wenn keine ähnlichen Künstler gefunden
        except requests.exceptions.HTTPError as e:
            if e.response.status_code == 404:
                print(f"Keine ähnlichen Künstler gefunden für ID: {id}")
                pyotherside.send("noSimilarArtists")
            else:
                print(f"HTTP Fehler beim Abrufen ähnlicher Künstler: {e}")
                pyotherside.send("apiError", str(e))
        except Exception as e:
            print(f"Allgemeiner Fehler beim Abrufen ähnlicher Künstler: {e}")
            pyotherside.send("apiError", str(e))
        finally:
            pyotherside.send('loadingFinished')

    def getFavorits(self, id):
        pyotherside.send('loadingStarted')
        albums = self.session.user.favorites.albums()
        for ti in albums:
            i = self.handle_album(ti)
            pyotherside.send("cacheAlbum", i)
            pyotherside.send("FavAlbums", i)

        tracks = self.session.user.favorites.tracks()
        for ti in tracks:
            i = self.handle_track(ti)
            pyotherside.send("cacheTrack", i)
            pyotherside.send("FavTracks", i)

        artists = self.session.user.favorites.artists()
        for ti in artists:
            i = self.handle_artist(ti)
            pyotherside.send("cacheArtist", i)
            pyotherside.send("FavArtist", i)

        pyotherside.send('loadingFinished')

    def homepage(self):
        self.home = self.session.home()
        #self.home.categories.extend(self.session.explore().categories)
        #self.home.categories.extend(self.session.videos().categories)

        for item in self.home.categories[0].items:
            self.getForYou(item)

        recent_page = self.getPageContinueListen()
        for item in recent_page:
            self.getRecently(item)

    def getRadioMixes(self):
        page = self.getPageSuggestedRadioMixes()
        for item in page:
            self.getCustomMixes("radioMix",item)

    def getDailyMixes(self):
        page = self.getPageDailyMixes()
        for item in page:
            self.getCustomMixes("dailyMix",item)

    def getTopArtists(self): # should there be a switch on get-artist in the end ?
        page = self.getPageFavoriteArtists()
        for item in page:
            self.tryHandleArtist("topArtist", item)

    def getPageContinueListen(self):
        return self.session.page.get("pages/CONTINUE_LISTEN_TO/view-all")

    def getPagePopularPlaylists(self):
        return self.session.page.get("pages/POPULAR_PLAYLISTS/view-all")

    def getPageSuggestedRadioMixes(self):
        return self.session.page.get("pages/SUGGESTED_RADIOS_MIXES/view-all?")

    def getPageDailyMixes(self):
        return self.session.page.get("pages/DAILY_MIXES/view-all?")

    # sorted by activity
    def getPageFavoriteArtists(self):
        return self.session.page.get("pages/YOUR_FAVORITE_ARTISTS/view-all?")

    def getPageListeningHistorypage(self):
        return self.session.page.get("pages/HISTORY_MIXES/view-all?")

    def getPageSuggestedNewAlbumspage(self):
        return self.session.page.get("pages/NEW_ALBUM_SUGGESTIONS/view-all?")

    def getPageDecades(self):
        return self.session.page.get("pages/genre_decades")

    def getPageGenres(self):
        return self.session.page.get("pages/genre_page")

    def getPageMoods(self):
        return self.session.page.get("pages/moods_page")

    def tryHandleAlbum(self, signalName, item):
        if isinstance(item, tidalapi.album.Album):
            album_info = self.handle_album(item)
            if album_info:
                self.send_object("cacheAlbum", album_info)
                self.send_object(signalName, album_info)
            else:
                pyotherside.send("printConsole", "trouble loading album")
            return True
        return False

    def tryHandleArtist(self, signalName, item):
        if isinstance(item, tidalapi.artist.Artist):
            # ps: crashes here self.items.append("\t" + item.name)
            pyotherside.send("printConsole", item.name)
            artist_info = self.handle_artist(item)
            if artist_info:
                self.send_object("cacheArtist", artist_info)
                self.send_object(signalName, artist_info)
            else:
                pyotherside.send("printConsole", "trouble loading artist")
            return True
        return False

    def tryHandlePlaylist(self, signalName, item):
        if isinstance(item, tidalapi.playlist.Playlist):
            playlist_info = self.handle_playlist(item)
            if playlist_info:
                self.send_object("cachePlaylist", playlist_info)
                self.send_object(signalName, playlist_info)
            return True
        return False

    def tryHandleMix(self, signalName, item, sub=None):
        # sub is used for customMixes
        if isinstance(item, tidalapi.mix.Mix):
            mix_info = self.handle_mix(item)
            if mix_info:
                self.send_object("cacheMix", mix_info)
                self.send_object(signalName, mix_info,sub)
            return True
        return False

    def tryHandleTrack(self, signalName, item):
        if isinstance(item, tidalapi.Track):
            track_info = self.handle_track(item)
            if track_info:
                self.send_object(signalName, track_info)
            return True
        return False

    def getRecently(self, item):
        if self.tryHandleAlbum("recentAlbum", item):
            return
        if self.tryHandleArtist("recentArtist", item):
            return
        if self.tryHandlePlaylist("recentPlaylist", item):
            return
        if self.tryHandleMix("recentMix", item):
            return
        if self.tryHandleTrack("recentTrack", item):
            return
        pyotherside.send("printConsole", f"trouble handling object in getRecently: {type(item)}")

    def getForYou(self, item):
        if self.tryHandleAlbum("foryouAlbum", item):
            return
        if self.tryHandleArtist("foryouArtist",item):
            return
        if self.tryHandlePlaylist("foryouPlaylist", item):
            return
        if self.tryHandleMix("foryouMix", item):
            return
        if self.tryHandleTrack("foryouTrack", item):
            return
        pyotherside.send("printConsole", f"trouble handling object in getForYou: {type(item)}")

    def getCustomMixes(self, sub, item):
        if self.tryHandleMix("customMix",item,sub):
            return
        pyotherside.send("printConsole", f"trouble handling object in getCustomMixes: {type(item)}")

    def getUser(self):
        return self.session.get_user(self.session.user.id)

    def setAlbumFavInfo(self,id,status):
        result = False
        if status:
            result = self.getUser().favorites.add_album(id)
        else:
            result = self.getUser().favorites.remove_album(id)
        if result:
            pyotherside.send('updateFavorite', id, status)

    def setArtistFavInfo(self,id,status):
        user = self.session.get_user(self.session.user.id)
        result = False
        if status:
            result = user.favorites.add_artist(id)
        else:
            result = user.favorites.remove_artist(id)
        if result:
            pyotherside.send('updateFavorite', id, status)

    def setTrackFavInfo(self,id,status):
        result = False
        if status:
            result = self.getUser().favorites.add_track(id)
        else:
            result = self.getUser().favorites.remove_track(id)
        if result:
            pyotherside.send('updateFavorite', id, status)

    def setPlaylistFavInfo(self,id,status):
        result = False
        if status:
            result = self.getUser().favorites.add_playlist(id)
        else:
            result = self.getUser().favorites.remove_playlist(id)
        if result:
            pyotherside.send('updateFavorite', id, status)
            
    def validateSession(self):
        """
        Validate if the current session is working properly
        Returns True if session is valid, False otherwise
        """
        try:
            if not hasattr(self, 'session') or not self.session:
                debug_log("No session object - validation failed", level=2)
                return False
                
            # Debug: Check session tokens
            if hasattr(self.session, 'access_token'):
                token_length = len(self.session.access_token) if self.session.access_token else 0
                debug_log(f"Session has access_token (length: {token_length})", level=2)
            
            if not hasattr(self.session, 'check_login'):
                debug_log("Session has no check_login method - validation failed", level=2)
                return False
                
            login_valid = self.session.check_login()
            debug_log(f"Session check_login result: {login_valid}", level=2)
            
            if not login_valid:
                debug_log("Session login check failed - validation failed", level=2)  
                return False
                
            debug_log("Session validation passed", level=2)
            return True
            
        except Exception as e:
            debug_log(f"Session validation error: {e}", level=1, force=True)
            return False

    def clearSession(self):
        """Clear the current session completely - for manual logout"""
        debug_log("Clearing TidalAPI session (manual logout)", level=1)
        
        try:
            if self.session:
                # Clear session tokens and user data
                session_cleared = False
                
                if hasattr(self.session, 'access_token'):
                    self.session.access_token = None
                    session_cleared = True
                if hasattr(self.session, 'refresh_token'):
                    self.session.refresh_token = None
                    session_cleared = True
                if hasattr(self.session, 'token_type'):
                    self.session.token_type = None
                    session_cleared = True
                if hasattr(self.session, 'expiry_time'):
                    self.session.expiry_time = None
                    session_cleared = True
                if hasattr(self.session, 'user'):
                    self.session.user = None
                    session_cleared = True
                
                # Clear any cached session state
                if hasattr(self.session, '_user_id'):
                    self.session._user_id = None
                if hasattr(self.session, 'session_id'):
                    self.session.session_id = None
                if hasattr(self.session, '_session_id'):
                    self.session._session_id = None
                    
                debug_log(f"Session tokens cleared: {session_cleared}", level=2)
                
                # Try to close/invalidate session if method exists
                if hasattr(self.session, 'close'):
                    self.session.close()
                    debug_log("Session closed", level=2)
                elif hasattr(self.session, 'logout'):
                    self.session.logout() 
                    debug_log("Session logout called", level=2)
                    
                # Force recreate session object to ensure clean state
                debug_log("Recreating session object for clean state", level=2)
                old_config = self.config
                self.session = None
                
                # Recreate with same config but clean state
                if old_config:
                    self.session = tidalapi.Session(old_config)
                    debug_log("New clean session created", level=2)
                else:
                    debug_log("No config available, session set to None", level=2)
                    
                debug_log("✓ TidalAPI session cleared and recreated successfully", level=1)
            else:
                debug_log("No active session to clear", level=1)
                
        except Exception as e:
            debug_log(f"Error clearing session: {str(e)} (Type: {type(e).__name__})", level=1, force=True)
            debug_log("Forcing session to None for safety", level=1)
            self.session = None

# Create global Tidal instance with error handling
try:
    debug_log("Creating global Tidal instance 'Tidaler'...", level=1)
    Tidaler = Tidal()
    debug_log("✓ Global Tidal instance created successfully", level=1)
except Exception as e:
    debug_log(f"✗ CRITICAL: Failed to create global Tidal instance: {str(e)}", level=1, force=True)
    debug_log(f"Error type: {type(e).__name__}", level=1, force=True)
    debug_log("This will prevent the app from working properly", level=1, force=True)
    raise
