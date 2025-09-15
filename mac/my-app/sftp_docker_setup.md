# SFTP Server Setup with Docker Compose

## ขั้นตอนที่ 1: สร้าง Directory Structure

```bash
mkdir sftp-server
cd sftp-server
mkdir -p config/keys
mkdir -p data/upload
mkdir -p logs
```

## ขั้นตอนที่ 2: สร้าง SSH Host Keys

สร้าง SSH host keys เพื่อให้ fingerprint ไม่เปลี่ยน:

```bash
# สร้าง RSA host key
ssh-keygen -t rsa -b 4096 -f config/keys/ssh_host_rsa_key -N "" -C "SFTP-Server-Host-Key"

# สร้าง ECDSA host key
ssh-keygen -t ecdsa -b 521 -f config/keys/ssh_host_ecdsa_key -N "" -C "SFTP-Server-Host-Key"

# สร้าง ED25519 host key
ssh-keygen -t ed25519 -f config/keys/ssh_host_ed25519_key -N "" -C "SFTP-Server-Host-Key"

# ตั้งค่า permissions
chmod 600 config/keys/ssh_host_*
chmod 644 config/keys/ssh_host_*.pub
```

## ขั้นตอนที่ 3: สร้าง User Keys

สร้าง SSH key pair สำหรับ user:

```bash
# สร้าง user key pair
ssh-keygen -t rsa -b 4096 -f config/keys/user_key -N "" -C "sftp-user@localhost"

# copy public key สำหรับใส่ใน authorized_keys
cp config/keys/user_key.pub config/keys/authorized_keys
chmod 644 config/keys/authorized_keys
```

## ขั้นตอนที่ 4: สร้าง Docker Compose File

```yaml
version: '3.8'

services:
  sftp:
    image: atmoz/sftp:latest
    container_name: sftp-server
    ports:
      - "2222:22"
    volumes:
      # Data directory
      - ./data:/home/sftpuser/upload
      
      # SSH host keys (เพื่อให้ fingerprint ไม่เปลี่ยน)
      - ./config/keys/ssh_host_rsa_key:/etc/ssh/ssh_host_rsa_key:ro
      - ./config/keys/ssh_host_rsa_key.pub:/etc/ssh/ssh_host_rsa_key.pub:ro
      - ./config/keys/ssh_host_ecdsa_key:/etc/ssh/ssh_host_ecdsa_key:ro
      - ./config/keys/ssh_host_ecdsa_key.pub:/etc/ssh/ssh_host_ecdsa_key.pub:ro
      - ./config/keys/ssh_host_ed25519_key:/etc/ssh/ssh_host_ed25519_key:ro
      - ./config/keys/ssh_host_ed25519_key.pub:/etc/ssh/ssh_host_ed25519_key.pub:ro
      
      # User authorized keys
      - ./config/keys/authorized_keys:/home/sftpuser/.ssh/authorized_keys:ro
      
      # Logs
      - ./logs:/var/log
    command: sftpuser:mypassword:1001:100:upload
    restart: unless-stopped
    environment:
      - SFTP_USERS=sftpuser:mypassword:1001:100:upload
    networks:
      - sftp-network

networks:
  sftp-network:
    driver: bridge
```

## ขั้นตอนที่ 5: สร้าง SSH Config File (สำหรับ Client)

```bash
# สร้างไฟล์ ssh_config สำหรับ client
cat > config/ssh_client_config << EOF
Host sftp-server
    HostName localhost
    Port 2222
    User sftpuser
    IdentityFile $(pwd)/config/keys/user_key
    StrictHostKeyChecking yes
    UserKnownHostsFile $(pwd)/config/known_hosts
    PasswordAuthentication no
    PubkeyAuthentication yes
EOF
```

## ขั้นตอนที่ 6: เริ่มต้น SFTP Server

```bash
# เริ่ม container
docker-compose up -d

# ตรวจสอบสถานะ
docker-compose logs sftp

# ดู fingerprint ของ server
ssh-keyscan -p 2222 localhost > config/known_hosts
```

## ขั้นตอนที่ 7: ทดสอบการเชื่อมต่อ

### ทดสอบด้วย SSH Key Authentication
```bash
# ทดสอบด้วย SSH
ssh -F config/ssh_client_config sftp-server

# ทดสอบด้วย SFTP
sftp -F config/ssh_client_config sftp-server

# หรือใช้ scp
scp -F config/ssh_client_config testfile.txt sftp-server:upload/
```

### ทดสอบด้วย Password Authentication
```bash
# ทดสอบด้วย SFTP (จะถาม password)
sftp -P 2222 sftpuser@localhost

# ทดสอบด้วย SCP (จะถาม password)
scp -P 2222 testfile.txt sftpuser@localhost:upload/

# ทดสอบด้วย SSH (จะถาม password)
ssh -p 2222 sftpuser@localhost
```

## ขั้นตอนที่ 8: ตรวจสอบ Host Key Fingerprint

```bash
# ดู fingerprint ของ RSA key
echo "=== RSA Host Key Fingerprint ==="
ssh-keygen -lf config/keys/ssh_host_rsa_key.pub
ssh-keygen -lf config/keys/ssh_host_rsa_key.pub -E md5
```

## การใช้งานจาก Client อื่น

### สำหรับ FileZilla หรือ WinSCP:
- **Host:** localhost หรือ IP ของ server
- **Port:** 2222
- **Protocol:** SFTP
- **Username:** sftpuser
- **Password:** mypassword (สำหรับ password auth)
- **Key file:** `config/keys/user_key` (สำหรับ key auth หรือแปลงเป็น .ppk สำหรับ WinSCP)

### สำหรับ Command Line:

#### Password Authentication:
```bash
# ใช้ password (จะถาม password)
sftp -P 2222 sftpuser@localhost
```

#### Key Authentication:
```bash
# ใช้ key file โดยตรง
sftp -i config/keys/user_key -P 2222 sftpuser@localhost

# หรือใช้ config file
sftp -F config/ssh_client_config sftp-server
```

#### Mixed Authentication (ทั้ง password และ key):
```bash
# จะลอง key ก่อน ถ้าไม่ได้จะถาม password
sftp -o PreferredAuthentications=publickey,password -P 2222 sftpuser@localhost
```

## Security Notes

1. **File Permissions:** ตรวจสอบให้แน่ใจว่า private keys มี permission 600
2. **Firewall:** จำกัดการเข้าถึง port 2222 เฉพาะ IP ที่ต้องการ
3. **Key Rotation:** พิจารณาเปลี่ยน keys เป็นระยะ
4. **Password Security:** ใช้ password ที่แข็งแรง และพิจารณาเปลี่ยนเป็นระยะ
5. **Monitoring:** ติดตาม logs ใน `./logs` directory
6. **Authentication Methods:** 
   - Key authentication มีความปลอดภัยสูงกว่า password
   - **หมายเหตุ:** atmoz/sftp image รองรับทั้ง password และ key authentication โดยอัตโนมัติ
   - ไม่จำเป็นต้องสร้าง sshd_config เพื่อเปิดใช้งาน password authentication
   - sshd_config จำเป็นเฉพาะเมื่อต้องการปรับแต่ง security settings เพิ่มเติม

### สำหรับการใช้งานปกติ:
**ไม่จำเป็นต้องสร้าง sshd_config** - เพียงแค่เปลี่ยน SFTP_USERS format ก็เพียงพอแล้ว

## Backup

```bash
# backup keys และ config
tar -czf sftp-backup-$(date +%Y%m%d).tar.gz config/

# backup data
tar -czf sftp-data-backup-$(date +%Y%m%d).tar.gz data/
```