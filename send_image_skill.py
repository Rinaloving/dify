#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
图片发送技能 - 支持中英文图片名
此技能用于发送桌面上的图片文件，无论图片文件名是否包含中文字符
"""

import os
import glob
import re


def find_and_send_image(image_name_pattern, desktop_path=None):
    """
    根据名称模式查找并发送图片
    
    Args:
        image_name_pattern: 图片名称模式（支持通配符）
        desktop_path: 桌面路径，默认为当前用户桌面
    
    Returns:
        图片路径列表
    """
    if desktop_path is None:
        # 获取当前用户桌面路径
        desktop_path = os.path.join(os.path.expanduser("~"), "Desktop")
    
    # 支持的图片格式
    image_extensions = ['*.png', '*.jpg', '*.jpeg', '*.gif', '*.bmp', '*.tiff', '*.webp']
    
    found_images = []
    
    # 遍历所有支持的图片格式
    for ext in image_extensions:
        # 使用glob查找匹配的图片文件
        pattern_path = os.path.join(desktop_path, f"*{image_name_pattern}*.{ext.split('.')[-1]}")
        matched_files = glob.glob(pattern_path, recursive=True)
        
        # 添加匹配的文件到结果列表
        for file_path in matched_files:
            if os.path.isfile(file_path):
                found_images.append(file_path)
    
    return found_images


def send_image_qq(image_path):
    """
    为QQ发送图片格式化路径
    
    Args:
        image_path: 图片完整路径
    
    Returns:
        QQ图片标签字符串
    """
    if os.path.exists(image_path):
        return f"<qqimg>{image_path}</qqimg>"
    else:
        return f"图片不存在: {image_path}"


def main():
    """
    主函数，演示如何使用该技能
    """
    print("图片发送技能 - 支持中英文图片名")
    print("示例用法:")
    
    # 示例：查找名为"AI"的图片
    ai_images = find_and_send_image("AI")
    print(f"找到包含'AI'的图片: {ai_images}")
    
    # 为每个找到的图片生成QQ发送格式
    for img_path in ai_images:
        qq_format = send_image_qq(img_path)
        print(f"QQ发送格式: {qq_format}")
    
    # 示例：查找包含中文"系统"的图片
    chinese_images = find_and_send_image("系统")
    print(f"找到包含'系统'的图片: {chinese_images}")
    
    # 为每个找到的图片生成QQ发送格式
    for img_path in chinese_images:
        qq_format = send_image_qq(img_path)
        print(f"QQ发送格式: {qq_format}")


if __name__ == "__main__":
    main()