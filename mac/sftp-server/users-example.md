# ตัวอย่างการจัดการ Users หลายคน

## Format สำหรับ SFTP_USERS

```
username:password:uid:gid:directory
```

## ตัวอย่าง Users หลายคน

### ใน docker-compose.yml:
```yaml
environment:
  - SFTP_USERS=user1:pass1:1001:100:upload user2:pass2:1002:100:data user3::1003:100:files
```

### คำอธิบาย:
- `user1:pass1:1001:100:upload` - user1 ใช้ password "pass1", uid=1001, gid=100, home dir="/home/user1/upload"
- `user2:pass2:1002:100:data` - user2 ใช้ password "pass2", uid=1002, gid=100, home dir="/home/user2/data"  
- `user3::1003:100:files` - user3 ไม่มี password (key only), uid=1003, gid=100, home dir="/home/user3/files"

## Volumes สำหรับ Users หลายคน

```yaml
volumes:
  # Data directories
  - ./data/user1:/home/user1/upload
  - ./data/user2:/home/user2/data
  - ./data/user3:/home/user3/files
  
  # Authorized keys สำหรับแต่ละ user
  - ./config/keys/user1_authorized_keys:/home/user1/.ssh/authorized_keys:ro
  - ./config/keys/user2_authorized_keys:/home/user2/.ssh/authorized_keys:ro
  - ./config/keys/user3_authorized_keys:/home/user3/.ssh/authorized_keys:ro
```

## การสร้าง Directory Structure

```bash
# สร้าง directories สำหรับแต่ละ user
mkdir -p data/user1 data/user2 data/user3
mkdir -p config/keys

# สร้าง authorized_keys สำหรับแต่ละ user
touch config/keys/user1_authorized_keys
touch config/keys/user2_authorized_keys  
touch config/keys/user3_authorized_keys

# ตั้งค่า permissions
chmod 644 config/keys/*_authorized_keys
```

## ตัวอย่างการเชื่อมต่อ

```bash
# User1 ด้วย password
sftp -P 2222 user1@localhost

# User2 ด้วย password
sftp -P 2222 user2@localhost

# User3 ด้วย key เท่านั้น
sftp -i config/keys/user3_key -P 2222 user3@localhost
```