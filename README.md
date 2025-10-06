การใช้งาน

บน Server:

sudo bash wg-server-setup.sh


→ script จะถาม interface, IP, port, Raspberry Pi public key

บน Raspberry Pi:

sudo bash wg-client-setup.sh


→ script จะถาม LAN interface, IP, Server public key/IP/port

หลังจากรันเสร็จ → PC หลัง switch ตั้ง Public IP ตรงตาม block ที่ ISP ให้
