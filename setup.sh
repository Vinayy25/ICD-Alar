#!/bin/bash

# Update package lists
echo "Updating package lists..."
sudo apt-get update

# Install necessary packages
echo "Installing necessary packages..."
sudo apt-get install -y \
    nginx \
    git \
    python3 \
    python3-pip \
    redis-server \
    tmux

# Configure Redis
echo "Configuring Redis..."
sudo systemctl start redis-server
sudo systemctl enable redis-server

# Verify Redis installation
echo "Verifying Redis installation..."
if redis-cli ping | grep -q "PONG"; then
    echo "Redis is running correctly."
else
    echo "Redis is not running correctly. Please check the installation."
    exit 1
fi

# Configure Nginx for the ICD API
echo "Configuring Nginx..."
sudo bash -c 'cat > /etc/nginx/sites-available/icd_api <<EOF
server {
    listen 80;
    server_name cognito.fun;  # Replace with your domain

    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF'

# Create symbolic link and test Nginx configuration
sudo ln -s /etc/nginx/sites-available/icd_api /etc/nginx/sites-enabled/
sudo nginx -t && sudo systemctl reload nginx

# Allow Nginx through firewall
sudo ufw allow 'Nginx Full'

# Install Python dependencies
echo "Installing Python packages..."
pip3 install fastapi
pip3 install "uvicorn[standard]"
pip3 install redis
pip3 install python-dotenv
pip3 install requests
pip3 install python-jose[cryptography]

# Create necessary directories
echo "Creating project directories..."
mkdir -p apis/uploads

# Create .env file if it doesn't exist
if [ ! -f .env ]; then
    echo "Creating .env file..."
    cat > .env <<EOF
ICD_CLIENT_ID=your_client_id
ICD_CLIENT_SECRET=your_client_secret
EOF
    echo "Created .env file. Please update with your actual credentials."
fi

# Create start script
echo "Creating start script..."
cat > start.sh <<EOF
#!/bin/bash
tmux new-session -d -s icd_api 'uvicorn main:app --host 0.0.0.0 --port 8000 --workers 15'
EOF
chmod +x start.sh

echo "Setup complete! To start the application:"
echo "1. Update the .env file with your ICD API credentials"
echo "2. Update the Nginx configuration with your domain"
echo "3. Run './start.sh' to start the API server"
echo "4. Visit http://cognito.fun to access the API"