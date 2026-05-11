// 由于安全限制，浏览器中的网页不能直接保存截图到磁盘
// 以下是一个前端截图功能的示例代码，需要配合服务器端或浏览器扩展实现完整功能

// 获取整个页面的截图并转换为Blob对象
async function capturePage() {
    try {
        // 检查是否支持html2canvas库
        if (!window.html2canvas) {
            throw new Error('html2canvas library is required');
        }

        // 获取整个页面容器
        const container = document.querySelector('.container');
        
        // 使用html2canvas生成截图
        const canvas = await html2canvas(container, {
            backgroundColor: '#ffffff',
            scale: 2, // 提高分辨率
            useCORS: true,
            allowTaint: true,
            width: container.scrollWidth,
            height: container.scrollHeight
        });

        // 将Canvas转换为Blob
        return new Promise((resolve) => {
            canvas.toBlob(resolve, 'image/png');
        });
    } catch (error) {
        console.error('Screenshot failed:', error);
        throw error;
    }
}

// 触发下载截图
async function downloadScreenshot() {
    try {
        const blob = await capturePage();
        
        // 创建下载链接
        const url = URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.href = url;
        a.download = `ai-agent-timeline-${new Date().toISOString().slice(0, 19)}.png`;
        
        // 触发下载
        document.body.appendChild(a);
        a.click();
        document.body.removeChild(a);
        
        // 释放URL对象
        URL.revokeObjectURL(url);
    } catch (error) {
        console.error('Download failed:', error);
        alert('截图失败，请尝试手动截取页面');
    }
}

// 添加截图按钮事件监听器
document.addEventListener('DOMContentLoaded', function() {
    const screenshotButton = document.getElementById('screenshot-btn');
    
    if (screenshotButton) {
        screenshotButton.addEventListener('click', downloadScreenshot);
    }
});