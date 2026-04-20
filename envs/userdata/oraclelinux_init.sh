#!/bin/bash

# Shell Options
# e : エラーがあったら直ちにシェルを終了
# u : 未定義変数を使用したときにエラーとする
# o : シェルオプションを有効にする
# pipefail : パイプラインの返り値を最後のエラー終了値にする (エラー終了値がない場合は0を返す)
set -euo pipefail

# Timezone
timedatectl set-timezone Asia/Tokyo
systemctl restart rsyslog

# Swap 変更 (defalt 1.5GiB)
# langpacks-ja インストール時にMAXで4GiB使っていたため、SWAP拡張で対応
# 元々/etc/fstabには永続化設定は入っているためコマンド実行はしない
swapoff /.swapfile
fallocate -l 5G /.swapfile
chmod 600 /.swapfile
mkswap /.swapfile
swapon /.swapfile

# Locale
dnf install -y langpacks-ja
localectl set-locale LANG=ja_JP.utf8
localectl set-keymap jp106

# Firewall Service disable
systemctl stop firewalld
systemctl disable firewalld
systemctl mask firewalld

# Nginx install
dnf install -y nginx
cat <<EOF > /usr/share/nginx/html/index.html
<!doctype html>
<html lang="ja">
  <head>
    <meta charset="UTF-8" />
    <title>Cloud-Init Test Page</title>
    <style>
      html,
      body {
        height: 100%;
        margin: 0;
      }
      body {
        display: flex;
        justify-content: center; /* 縦方向中央 */
        align-items: center; /* 横方向中央 */
        font-family: Arial, Helvetica, sans-serif;
        background-color: #f4f4f4;
      }
      .container {
        background: #ffffff;
        padding: 30px 40px;
        border-radius: 6px;
        max-width: 800px;
        box-shadow: 0 0 10px rgba(0, 0, 0, 0.1);
        text-align: center;
      }
      h1 {
        color: #333333;
        margin-top: 0;
      }
      p {
        font-size: 14px;
        line-height: 1.6;
      }
    </style>
  </head>

  <body>
    <div class="container">
      <h1>nginx is working!</h1>
      <p>This page was created automatically by cloud-init user-data.</p>
      <p>
        If you are seeing this page, nginx has been installed and started
        successfully.
      </p>
    </div>
  </body>
</html>
EOF
systemctl enable --now nginx

# SELinux disable
grubby --update-kernel ALL --args selinux=0
shutdown -r now