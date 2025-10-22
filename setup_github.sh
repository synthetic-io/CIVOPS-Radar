#!/bin/bash
# CIVOPS-Radar: GitHub Setup Script
# This script helps you deploy CIVOPS-Radar to GitHub

set -euo pipefail

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}🚀 CIVOPS-Radar GitHub Deployment Setup${NC}"
echo ""

# Check if git is configured
if ! git config user.name > /dev/null 2>&1; then
    echo -e "${YELLOW}⚠ Git user not configured. Please set up git first:${NC}"
    echo "git config --global user.name 'Your Name'"
    echo "git config --global user.email 'your.email@example.com'"
    exit 1
fi

echo -e "${GREEN}✓ Git is configured${NC}"

# Get GitHub username
echo ""
echo -e "${BLUE}📝 GitHub Setup Information${NC}"
echo "Please provide your GitHub information:"
echo ""

read -p "GitHub Username: " GITHUB_USERNAME
read -p "Repository Name (default: CIVOPS-Radar): " REPO_NAME
REPO_NAME=${REPO_NAME:-CIVOPS-Radar}

echo ""
echo -e "${BLUE}🔧 Configuration Summary:${NC}"
echo "  Username: $GITHUB_USERNAME"
echo "  Repository: $REPO_NAME"
echo "  URL: https://github.com/$GITHUB_USERNAME/$REPO_NAME.git"
echo ""

read -p "Continue with deployment? (y/N): " CONFIRM
if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
    echo "Deployment cancelled."
    exit 0
fi

# Update mobile installer with correct GitHub URL
echo -e "${BLUE}📝 Updating mobile installer...${NC}"
sed -i.bak "s|https://github.com/your-username/CIVOPS-Radar.git|https://github.com/$GITHUB_USERNAME/$REPO_NAME.git|g" termux/mobile_install.sh
sed -i.bak "s|YOUR_USERNAME|$GITHUB_USERNAME|g" DEPLOYMENT.md
sed -i.bak "s|YOUR_USERNAME|$GITHUB_USERNAME|g" README.md

# Add remote origin
echo -e "${BLUE}🔗 Adding GitHub remote...${NC}"
git remote add origin "https://github.com/$GITHUB_USERNAME/$REPO_NAME.git" 2>/dev/null || git remote set-url origin "https://github.com/$GITHUB_USERNAME/$REPO_NAME.git"

# Commit changes
echo -e "${BLUE}💾 Committing changes...${NC}"
git add .
git commit -m "Update GitHub URLs for deployment" || echo "No changes to commit"

# Push to GitHub
echo -e "${BLUE}🚀 Pushing to GitHub...${NC}"
git push -u origin main || git push -u origin master

echo ""
echo -e "${GREEN}✅ CIVOPS-Radar deployed to GitHub!${NC}"
echo ""
echo -e "${BLUE}📱 Mobile Installation Commands:${NC}"
echo ""
echo "1. Install Termux from F-Droid"
echo "2. Run this command on your phone:"
echo ""
echo -e "${YELLOW}curl -sSL https://raw.githubusercontent.com/$GITHUB_USERNAME/$REPO_NAME/main/termux/mobile_install.sh | bash${NC}"
echo ""
echo -e "${BLUE}🌐 Web Access:${NC}"
echo "  Repository: https://github.com/$GITHUB_USERNAME/$REPO_NAME"
echo "  Mobile Install: https://raw.githubusercontent.com/$GITHUB_USERNAME/$REPO_NAME/main/termux/mobile_install.sh"
echo ""
echo -e "${BLUE}📖 Documentation:${NC}"
echo "  - README.md: Project overview and quick start"
echo "  - DEPLOYMENT.md: Detailed deployment guide"
echo "  - docs/: Technical documentation"
echo ""
echo -e "${GREEN}🎉 Ready for mobile deployment!${NC}"
