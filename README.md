# Báo Cáo Thực Hành: Quản Lý Tiến Trình Nền Với nohup Và Tín Hiệu Kill

- **Môn học:** Hệ Điều Hành / Linux System Administration
- **Bài tập:** Bài 4 - Quản lý tiến trình nền với nohup và tín hiệu Kill
- **Đường dẫn nộp bài:** `homework/session_06/ex4/`
- **Mã nguồn đính kèm:** [`loop-monitor.sh`](file:///d:/IT209/SS06/BAI4/loop-monitor.sh)

---

## 1. Mục tiêu bài thực hành
- Nắm vững kỹ thuật khởi chạy tiến trình chạy nền độc lập với phiên làm việc Terminal bằng công cụ `nohup` và toán tử `&`.
- Thành thạo việc giám sát, tra cứu trạng thái tiến trình và mã định danh tiến trình (PID) thông qua các lệnh `ps`, `pgrep`, `top`/`htop`.
- Hiểu rõ bản chất các tín hiệu hệ thống (Signals), thực hiện dừng tiến trình một cách an toàn bằng `kill` với `SIGTERM (15)` và phương án cưỡng chế dừng bằng `SIGKILL (9)`.

---

## 2. Mã nguồn kịch bản giám sát (`loop-monitor.sh`)

Script lặp vô hạn, cứ mỗi 5 giây sẽ ghi nhận thời gian hiện tại của hệ thống vào tệp `/tmp/monitor.log`:

```bash
#!/bin/bash

# Kịch bản giám sát hệ thống (loop-monitor.sh)
# Ghi thời gian hiện tại vào tệp /tmp/monitor.log mỗi 5 giây

LOG_FILE="/tmp/monitor.log"

while true; do
    echo "System time: $(date)" >> "$LOG_FILE"
    sleep 5
done
```

---

## 3. Các bước thực hiện và kết quả

### Bước 1: Phân quyền thực thi cho script
Trước khi chạy, ta cần gán quyền thực thi cho tệp kịch bản:
```bash
chmod +x loop-monitor.sh
```

---

### Bước 2: Khởi chạy kịch bản dưới nền độc lập với `nohup`
Khởi chạy script ở chế độ nền độc lập hoàn toàn với session hiện tại:
```bash
nohup ./loop-monitor.sh > /dev/null 2>&1 &
```

**Giải thích cú pháp lệnh:**
- `nohup` (*No Hang Up*): Bắt và bỏ qua tín hiệu `SIGHUP` (Signal Hang Up), giúp tiến trình không bị tắt khi người dùng thoát terminal hoặc mất kết nối SSH.
- `./loop-monitor.sh`: Kịch bản cần thực thi.
- `> /dev/null`: Điều hướng đầu ra tiêu chuẩn (stdout) vào "hố đen" `/dev/null` để tránh tạo tệp `nohup.out` mặc định (vì script đã chủ động ghi vào `/tmp/monitor.log`).
- `2>&1`: Điều hướng đầu ra lỗi (stderr - luồng 2) vào cùng nơi với stdout (luồng 1).
- `&`: Đẩy tiến trình xuống chạy ngầm (background job), trả quyền điều khiển prompt cho người dùng ngay lập tức.

**Kết quả màn hình khi chạy:**
```text
[1] 24891
```
*(Trong đó `[1]` là Job ID, `24891` là Process ID - PID khởi tạo).*

---

### Bước 3: Tìm số định danh tiến trình (PID)

Sử dụng lệnh `pgrep` hoặc `ps aux` để kiểm tra tiến trình đang hoạt động:

```bash
# Cách 1: Sử dụng pgrep
pgrep -f loop-monitor.sh
```
**Kết quả:**
```text
24891
```

```bash
# Cách 2: Sử dụng ps kết hợp grep
ps aux | grep loop-monitor.sh
```
**Kết quả hiển thị:**
```text
user   24891  0.0  0.1  13248  3120 ?    S    21:55   0:00 /bin/bash ./loop-monitor.sh
user   24940  0.0  0.0  12112  1048 pts/0 S+ 21:55   0:00 grep --color=auto loop-monitor.sh
```
*Nhận xét:* Tiến trình `loop-monitor.sh` đang chạy với PID là **`24891`**, cột TTY hiển thị dấu `?` nghĩa là tiến trình không còn gắn liền với một terminal cụ thể nào.

---

### Bước 4: Kiểm tra tệp tin log đang được ghi liên tục

Kiểm tra nội dung tệp `/tmp/monitor.log` để xác nhận tiến trình ghi nhận dữ liệu định kỳ mỗi 5 giây:

```bash
tail -n 10 /tmp/monitor.log
```
**Kết quả hiển thị:**
```text
System time: Mon Oct  5 21:55:05 +07 2026
System time: Mon Oct  5 21:55:10 +07 2026
System time: Mon Oct  5 21:55:15 +07 2026
System time: Mon Oct  5 21:55:20 +07 2026
System time: Mon Oct  5 21:55:25 +07 2026
System time: Mon Oct  5 21:55:30 +07 2026
System time: Mon Oct  5 21:55:35 +07 2026
System time: Mon Oct  5 21:55:40 +07 2026
System time: Mon Oct  5 21:55:45 +07 2026
System time: Mon Oct  5 21:55:50 +07 2026
```
*(Dữ liệu thời gian được ghi liên tục mỗi 5 giây đúng như thiết kế trong kịch bản).*

---

### Bước 5: Kiểm tra tính độc lập (Persistence) khi ngắt phiên làm việc
1. Đóng hẳn cửa sổ Terminal / thoát SSH bằng lệnh `exit`.
2. Mở một cửa sổ Terminal mới và kiểm tra lại:
```bash
ps aux | grep loop-monitor.sh
tail -n 5 /tmp/monitor.log
```
*Kết quả:* Tiến trình vẫn tiếp tục duy trì PID `24891` và tệp `/tmp/monitor.log` vẫn được cập nhật liên tục, chứng minh `nohup` đã bảo vệ tiến trình khỏi việc bị chấm dứt bởi tín hiệu `SIGHUP`.

---

### Bước 6: Tắt tiến trình an toàn bằng tín hiệu SIGTERM (15)

Thực hiện dừng tiến trình bằng tín hiệu `SIGTERM (15)` để cho phép tiến trình đóng tài nguyên một cách an toàn:

```bash
kill -15 24891
```
*(Hoặc dùng `kill 24891` do tín hiệu mặc định của lệnh kill chính là 15).*

**Kiểm tra lại xem tiến trình đã kết thúc chưa:**
```bash
ps aux | grep loop-monitor.sh
```
**Kết quả:**
```text
user   25102  0.0  0.0  12112  1048 pts/1 S+ 21:58   0:00 grep --color=auto loop-monitor.sh
```
*Nhận xét:* Tiến trình `loop-monitor.sh` với PID `24891` đã kết thúc hoàn toàn và không còn xuất hiện trong bảng danh sách tiến trình của hệ thống.

> **Lưu ý về phương án dự phòng (SIGKILL - 9):**
> Trong trường hợp tiến trình bị treo (Deadlock hoặc Uninterruptible Sleep) và không phản hồi tín hiệu `SIGTERM`, ta dùng tín hiệu cưỡng chế dừng ngay lập tức ở mức Kernel:
> ```bash
> kill -9 <PID>
> ```

---

## 4. So sánh cơ chế tín hiệu SIGTERM (15) vs SIGKILL (9)

| Đặc điểm | SIGTERM (Tín hiệu số 15) | SIGKILL (Tín hiệu số 9) |
| :--- | :--- | :--- |
| **Mục đích** | Yêu cầu tiến trình dừng một cách nhẹ nhàng (Graceful Termination). | Buộc dừng tiến trình ngay lập tức (Force Kill). |
| **Xử lý tín hiệu** | Tiến trình có thể bắt (catch), xử lý (handle) hoặc bỏ qua tín hiệu để giải phóng bộ nhớ, đóng file descriptor, xóa file lock tạm. | Do nhân Kernel trực tiếp xử lý, tiến trình **không thể** bắt, chặn hay bỏ qua tín hiệu này. |
| **Mức độ rủi ro** | An toàn, tránh gây hỏng hóc hoặc mất mát dữ liệu đang ghi dở. | Có thể để lại file tạm, socket rác hoặc dữ liệu tệp tin bị hỏng (corrupted data). |
| **Thực hành chuẩn** | **Luôn ưu tiên gửi SIGTERM (15) trước.** | Chỉ sử dụng khi SIGTERM không có tác dụng. |

---

## 5. Kết luận
Bài thực hành đã hoàn thành đầy đủ tất cả các yêu cầu:
1. Xây dựng thành công kịch bản `loop-monitor.sh` ghi log hệ thống định kỳ.
2. Khởi chạy và cô lập tiến trình nền độc lập bằng `nohup ... &`.
3. Giám sát tiến trình bằng `ps`, `pgrep` và theo dõi luồng log qua `tail`.
4. Dừng tiến trình đúng quy chuẩn bằng lệnh `kill` với tín hiệu `SIGTERM (15)`.
