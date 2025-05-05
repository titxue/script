# 参考地址：https://club.fnnas.com/forum.php?mod=viewthread&tid=16025
#!/bin/bash

#配置
CERT_NAME="*"
PANEL_CERT_PATH="/vol1/1000/data/certs"
FNOS_CERT_PATH="/usr/trim/var/trim_connect/ssls/*/1746413929"

# 重命名
mv "$PANEL_CERT_PATH/fullchain.pem" "$PANEL_CERT_PATH/$CERT_NAME.crt"
mv "$PANEL_CERT_PATH/privkey.pem" "$PANEL_CERT_PATH/$CERT_NAME.key"

# 删除目标路径的旧文件（如果存在）
rm -f "$FNOS_CERT_PATH/$CERT_NAME.crt" "$FNOS_CERT_PATH/$CERT_NAME.key"

# 创建软连接（替换原来的cp命令）
ln -sf "$PANEL_CERT_PATH/$CERT_NAME.crt" "$FNOS_CERT_PATH/$CERT_NAME.crt"
ln -sf "$PANEL_CERT_PATH/$CERT_NAME.key" "$FNOS_CERT_PATH/$CERT_NAME.key"

# 获取新证书的到期日期并更新数据库中的证书有效期
NEW_EXPIRY_DATE=$(openssl x509 -enddate -noout -in "$FNOS_CERT_PATH/$CERT_NAME.crt" | awk -F'=' '{print $2}')
NEW_EXPIRY_TIMESTAMP=$(date -d "$NEW_EXPIRY_DATE" +%s%3N)  # 获取毫秒级时间戳

# 更新数据库中的证书有效期
psql -U postgres -d trim_connect -c "UPDATE cert SET valid_to=$NEW_EXPIRY_TIMESTAMP WHERE domain='$CERT_NAME'"

# 重启服务
systemctl restart webdav.service
systemctl restart smbftpd.service
systemctl restart trim_nginx.service

