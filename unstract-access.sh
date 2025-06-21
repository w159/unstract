#!/bin/bash
# Unstract Access Helper

echo "=== Unstract Access Guide ==="
echo ""
echo "Due to Traefik routing issues, use these direct URLs:"
echo ""
echo "✅ Working Access Points:"
echo "  - Frontend: http://localhost:3000"
echo "  - Backend API: http://localhost:8000"
echo "  - MinIO Console: http://localhost:9001 (user: minio, pass: minio123)"
echo "  - Traefik Dashboard: http://localhost:8080"
echo ""
echo "The frontend.unstract.localhost routing has a configuration issue where"
echo "Traefik is trying to connect to the wrong port inside the container."
echo ""
echo "Opening frontend in browser..."
open http://localhost:3000 2>/dev/null || xdg-open http://localhost:3000 2>/dev/null || echo "Please open http://localhost:3000 in your browser"