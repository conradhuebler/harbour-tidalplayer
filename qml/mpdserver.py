# This Python file uses the following encoding: utf-8
# Claude Generated
"""Hands a DASH manifest to MediaPlayer.

Tidal serves Hi-Res as an MPEG-DASH manifest (FLAC in fragmented MP4) that comes
inline, not as a URL. GStreamer's dashdemux streams it, but needs a URL to the
manifest: it is published on a loopback-only HTTP server. Nothing else passes
through here - GStreamer fetches the audio segments from Tidal itself.
"""
import binascii
import os
import threading
from collections import OrderedDict
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

_KEEP_MANIFESTS = 8


class _Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        body = self.server.manifests.get(self.path)
        if body is None:
            self.send_error(404)
            return
        self.send_response(200)
        self.send_header('Content-Type', 'application/dash+xml')
        self.send_header('Content-Length', str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def log_message(self, *args):
        pass


class ManifestServer:
    def __init__(self):
        self._lock = threading.Lock()
        self._server = None
        # the random path segment keeps other local apps from guessing the URL
        self._secret = binascii.hexlify(os.urandom(8)).decode()

    def _ensure_started(self):
        if self._server is None:
            server = ThreadingHTTPServer(('127.0.0.1', 0), _Handler)
            server.daemon_threads = True
            server.manifests = OrderedDict()
            threading.Thread(target=server.serve_forever, daemon=True).start()
            self._server = server
        return self._server

    def publish(self, name, mpd_xml):
        """Serve mpd_xml and return the URL of the manifest."""
        with self._lock:
            server = self._ensure_started()
            path = "/%s/%s.mpd" % (self._secret, name)
            server.manifests[path] = mpd_xml.encode('utf-8')
            while len(server.manifests) > _KEEP_MANIFESTS:
                server.manifests.popitem(last=False)
            return "http://127.0.0.1:%d%s" % (server.server_address[1], path)
