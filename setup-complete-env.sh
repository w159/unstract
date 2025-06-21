#!/usr/bin/env bash

# This script ensures all environment files are properly set up for Unstract

set -e

echo "Setting up complete environment for Unstract..."

# Generate encryption key
ENCRYPTION_KEY=$(python3 -c "import secrets, base64; print(base64.urlsafe_b64encode(secrets.token_bytes(32)).decode())")

# Create backend/.env if it doesn't exist
if [ ! -f "backend/.env" ]; then
    cp backend/sample.env backend/.env
    echo "Created backend/.env from sample"
    
    # Update encryption key
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' "s/ENCRYPTION_KEY=.*/ENCRYPTION_KEY=\"$ENCRYPTION_KEY\"/" backend/.env
    else
        sed -i "s/ENCRYPTION_KEY=.*/ENCRYPTION_KEY=\"$ENCRYPTION_KEY\"/" backend/.env
    fi
fi

# Create platform-service/.env if it doesn't exist
if [ ! -f "platform-service/.env" ]; then
    cp platform-service/sample.env platform-service/.env
    echo "Created platform-service/.env from sample"
    
    # Update encryption key to match backend
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' "s/ENCRYPTION_KEY=.*/ENCRYPTION_KEY=\"$ENCRYPTION_KEY\"/" platform-service/.env
    else
        sed -i "s/ENCRYPTION_KEY=.*/ENCRYPTION_KEY=\"$ENCRYPTION_KEY\"/" platform-service/.env
    fi
fi

# Create prompt-service/.env if it doesn't exist
if [ ! -f "prompt-service/.env" ]; then
    cp prompt-service/sample.env prompt-service/.env
    echo "Created prompt-service/.env from sample"
fi

# Create x2text-service/.env if it doesn't exist
if [ ! -f "x2text-service/.env" ]; then
    cp x2text-service/sample.env x2text-service/.env
    echo "Created x2text-service/.env from sample"
fi

# Create runner/.env if it doesn't exist
if [ ! -f "runner/.env" ]; then
    cp runner/sample.env runner/.env
    echo "Created runner/.env from sample"
fi

# Create docker/essentials.env if it doesn't exist
if [ ! -f "docker/essentials.env" ]; then
    cp docker/sample.essentials.env docker/essentials.env
    echo "Created docker/essentials.env from sample"
fi

# Create docker/.env if it doesn't exist
if [ ! -f "docker/.env" ]; then
    cp docker/sample.env docker/.env
    echo "Created docker/.env from sample"
fi

# Create frontend/.env if it doesn't exist
if [ ! -f "frontend/.env" ]; then
    cat > frontend/.env <<EOF
# Frontend environment variables
REACT_APP_BACKEND_URL=http://frontend.unstract.localhost
REACT_APP_ENABLE_POSTHOG=false
REACT_APP_POSTHOG_KEY=
REACT_APP_POSTHOG_HOST=
EOF
    echo "Created frontend/.env"
fi

echo ""
echo "✅ Environment setup complete!"
echo ""
echo "🔐 IMPORTANT: Save this encryption key in a secure location:"
echo "   ENCRYPTION_KEY=$ENCRYPTION_KEY"
echo ""
echo "📝 Default credentials:"
echo "   Username: unstract"
echo "   Password: unstract"
echo ""
echo "🚀 You can now run: ./run-platform.sh"