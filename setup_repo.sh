#!/bin/bash

# Create directory structure
mkdir -p docs
mkdir -p src
mkdir -p build

# Create .gitignore to ignore compiled files
cat > .gitignore << 'EOF'
# Compiled files
*.img
*.bin
*.o

# Build directory contents (but keep the folder)
build/*
!build/.gitkeep

# Editor files
*.swp
*~
.DS_Store
EOF

# Keep build directory in git
touch build/.gitkeep

echo "Repository structure created!"
