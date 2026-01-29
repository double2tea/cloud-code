# Zeabur 部署指南 (无 FUSE 版本)

## 🚀 快速部署到 Zeabur

### ✅ 问题解决
- **移除 FUSE 依赖** - 不再需要 `fusermount` 和 `TigrisFS`
- **直接 S3 访问** - 使用 AWS CLI 和 SDK 直接操作 S3
- **定期同步** - 每 5 分钟自动同步到 S3
- **优雅关闭** - 关闭时自动保存到 S3

### 方法 1: 通过 GitHub 部署 (推荐)

1. **推送更新的代码**
   ```bash
   git add Dockerfile.zeabur
   git commit -m "Fix FUSE issue: Use direct S3 access instead of FUSE mounting"
   git push origin master
   ```

2. **在 Zeabur 控制台重新部署**
   - 访问 [Zeabur 控制台](https://dash.zeabur.com)
   - 找到你的项目
   - 点击 "Redeploy" 或触发新的部署

3. **配置环境变量**
   确保以下环境变量已设置：
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

## 🔧 新的工作方式

### S3 同步机制
- **启动时**: 从 S3 下载现有文件到本地工作区
- **运行时**: 每 5 分钟自动同步本地更改到 S3
- **关闭时**: 最终同步确保数据不丢失

### 优势
- ✅ **兼容 Zeabur** - 不依赖 FUSE 设备
- ✅ **数据持久化** - 文件自动保存到 S3
- ✅ **性能优化** - 本地操作，定期同步
- ✅ **容错性强** - 即使 S3 不可用也能正常运行

## 📋 部署后检查

1. **查看启动日志**
   ```
   [INFO] Setting up S3 configuration for direct access
   [OK] S3 connection successful
   [INFO] Syncing files from S3...
   [INFO] Background S3 sync started (PID: xxx)
   [INFO] Starting OpenCode on port 2633...
   ```

2. **测试功能**
   - 访问 Zeabur 提供的 URL
   - 创建/编辑文件
   - 等待 5 分钟后检查 S3 存储桶

3. **监控同步**
   - 查看应用日志中的同步消息
   - 检查 S3 存储桶中的文件更新

## 🛠️ 故障排除

### 常见问题
- **S3 连接失败**: 检查环境变量配置
- **同步失败**: 检查 S3 权限和网络连接
- **启动慢**: AWS CLI 安装需要时间，属正常现象

### 日志关键词
- `[OK] S3 connection successful` - S3 连接成功
- `[INFO] Background S3 sync started` - 同步进程启动
- `[INFO] Syncing workspace to S3` - 定期同步执行

## 💡 性能优化

- **本地优先**: 所有操作在本地进行，响应快速
- **批量同步**: 避免频繁的 S3 操作
- **增量同步**: 只同步变更的文件
- **后台处理**: 同步不影响主服务

现在你的应用应该能在 Zeabur 上正常运行了！🎉