# Zeabur 部署指南

## 🚀 快速部署到 Zeabur

### 方法 1: 通过 GitHub 部署 (推荐)

1. **推送代码到 GitHub**
   ```bash
   git add .
   git commit -m "Add Zeabur deployment configuration"
   git push origin main
   ```

2. **在 Zeabur 控制台部署**
   - 访问 [Zeabur 控制台](https://dash.zeabur.com)
   - 点击 "New Project"
   - 选择 "Deploy from GitHub"
   - 选择你的 `cloud-code` 仓库
   - Zeabur 会自动检测 Dockerfile 并开始构建

3. **配置环境变量**
   在 Zeabur 项目设置中添加以下环境变量：
   ```
   NODE_ENV=production
   PORT=2633
   S3_ENDPOINT=https://4fe3598337e00d68ea219bd315055543.r2.cloudflarestorage.com
   S3_BUCKET=cloud-code
   S3_ACCESS_KEY_ID=c5846289fce4d82bc14425ba7b9d9b97
   S3_SECRET_ACCESS_KEY=5084fe65a9e7d8f2abbcac916d958607838ad5c4aee9a87b0e09ae933dbd5fa5
   S3_REGION=auto
   S3_PATH_STYLE=false
   S3_PREFIX=cloud-code
   ```

### 方法 2: 直接上传部署

1. **创建项目压缩包**
   ```bash
   tar -czf cloud-code.tar.gz --exclude=node_modules --exclude=.git .
   ```

2. **在 Zeabur 控制台**
   - 选择 "Upload Files"
   - 上传 `cloud-code.tar.gz`
   - 配置环境变量（同上）

### 方法 3: 使用 Docker Hub

1. **构建并推送镜像**
   ```bash
   docker build -f Dockerfile.zeabur -t your-username/cloud-code:latest .
   docker push your-username/cloud-code:latest
   ```

2. **在 Zeabur 部署**
   - 选择 "Deploy from Docker Image"
   - 输入镜像名: `your-username/cloud-code:latest`

## 📋 部署后检查

1. **访问应用**
   - Zeabur 会提供一个公网 URL
   - 访问该 URL 确认服务正常运行

2. **查看日志**
   - 在 Zeabur 控制台查看应用日志
   - 确认 OpenCode 正常启动

3. **测试功能**
   - 确认 AI 编程助手功能正常
   - 测试文件上传和 S3 存储

## 🔧 故障排除

- **构建失败**: 检查 Dockerfile.zeabur 语法
- **启动失败**: 查看环境变量配置
- **访问失败**: 确认端口配置 (2633)

## 💡 优势

- ✅ 自动 HTTPS
- ✅ 全球 CDN
- ✅ 自动扩容
- ✅ 零配置部署
- ✅ 免费额度