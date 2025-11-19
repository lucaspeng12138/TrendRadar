# coding=utf-8
"""
WeChat Image Upload Module
上传图片到微信公众号永久素材库
"""

import os
import sys
import requests
from pathlib import Path
import yaml


def load_config():
    """加载配置文件"""
    config_path = os.environ.get("CONFIG_PATH", "config/config.yaml")

    if not Path(config_path).exists():
        raise IOError("配置文件 {0} 不存在".format(config_path))

    with open(config_path, "r", encoding="utf-8") as f:
        config_data = yaml.safe_load(f)

    return config_data


def get_wechat_access_token(app_id, app_secret, proxy_url=None):
    """获取微信公众号access_token"""
    if not app_id or not app_secret:
        print("错误：WeChat AppID 或 AppSecret 未配置或为空")
        return None

    url = "https://api.weixin.qq.com/cgi-bin/token?grant_type=client_credential&appid={0}&secret={1}".format(app_id, app_secret)

    proxies = None
    if proxy_url:
        proxies = {"http": proxy_url, "https": proxy_url}

    try:
        response = requests.get(url, proxies=proxies, timeout=10)
        response.raise_for_status()

        data = response.json()

        if "access_token" in data:
            print("成功获取微信access_token")
            return data["access_token"]
        else:
            print("获取微信access_token失败: {0}".format(data))
            return None
    except Exception as e:
        print("获取微信access_token出错: {0}".format(e))
        return None


def upload_image_to_wechat(image_path, access_token, proxy_url=None):
    """
    上传图片到微信公众号永久素材库

    Args:
        image_path: 图片文件路径
        access_token: 微信access_token
        proxy_url: 代理URL（可选）

    Returns:
        tuple: (是否成功, 响应数据)
    """
    if not os.path.exists(image_path):
        return False, {"error": "图片文件不存在: {0}".format(image_path)}

    # 检查文件大小（微信限制10MB）
    file_size = os.path.getsize(image_path)
    if file_size > 10 * 1024 * 1024:  # 10MB
        return False, {"error": "图片文件过大: {0} bytes (限制10MB)".format(file_size)}

    # 检查文件格式
    allowed_extensions = {'.jpg', '.jpeg', '.png', '.gif', '.bmp'}
    file_ext = Path(image_path).suffix.lower()
    if file_ext not in allowed_extensions:
        return False, {"error": "不支持的图片格式: {0} (支持: {1})".format(file_ext, ', '.join(allowed_extensions))}

    url = "https://api.weixin.qq.com/cgi-bin/material/add_material?access_token={0}&type=image".format(access_token)

    proxies = None
    if proxy_url:
        proxies = {"http": proxy_url, "https": proxy_url}

    try:
        with open(image_path, 'rb') as f:
            files = {'media': f}
            response = requests.post(url, files=files, proxies=proxies, timeout=30)

        response.raise_for_status()
        data = response.json()

        if "media_id" in data:
            print("图片上传成功！")
            print("Media ID: {0}".format(data['media_id']))
            if "url" in data:
                print("图片URL: {0}".format(data['url']))
            return True, data
        else:
            print("上传失败: {0}".format(data))
            return False, data

    except requests.exceptions.HTTPError as e:
        print("HTTP错误: {0}".format(e))
        try:
            error_data = response.json()
            print("错误详情: {0}".format(error_data))
            return False, error_data
        except:
            return False, {"error": str(e)}
    except Exception as e:
        print("上传图片出错: {0}".format(e))
        return False, {"error": str(e)}


def main():
    """主函数：上传图片到微信公众号"""
    if len(sys.argv) < 2:
        print("用法: python upload_image.py <图片文件路径>")
        print("示例: python upload_image.py image.jpg")
        sys.exit(1)

    image_path = sys.argv[1]

    try:
        # 加载配置
        config = load_config()

        # 获取微信配置
        wechat_config = config.get("notification", {}).get("webhooks", {})
        app_id = wechat_config.get("wechat_app_id", "").strip()
        app_secret = wechat_config.get("wechat_app_secret", "").strip()

        if not app_id:
            app_id = os.environ.get("WECHAT_APP_ID", "").strip()
        if not app_secret:
            app_secret = os.environ.get("WECHAT_APP_SECRET", "").strip()

        if not app_id or not app_secret:
            print("错误：未配置微信公众号AppID或AppSecret")
            print("请在config/config.yaml中配置:")
            print("  notification:")
            print("    webhooks:")
            print("      wechat_app_id: \"你的AppID\"")
            print("      wechat_app_secret: \"你的AppSecret\"")
            sys.exit(1)

        # 获取代理配置
        proxy_url = None
        if config.get("crawler", {}).get("use_proxy", False):
            proxy_url = config["crawler"].get("default_proxy")

        # 获取access_token
        print("正在获取微信access_token...")
        access_token = get_wechat_access_token(app_id, app_secret, proxy_url)
        if not access_token:
            print("获取access_token失败，请检查配置")
            sys.exit(1)

        # 上传图片
        print("正在上传图片: {0}".format(image_path))
        success, result = upload_image_to_wechat(image_path, access_token, proxy_url)

        if success:
            print("\n上传成功！")
            print("Media ID: {0}".format(result.get('media_id')))
            print("图片URL: {0}".format(result.get('url', 'N/A')))
        else:
            print("\n上传失败！")
            print("错误信息: {0}".format(result))
            sys.exit(1)

    except Exception as e:
        print("程序执行出错: {0}".format(e))
        sys.exit(1)


if __name__ == "__main__":
    main()