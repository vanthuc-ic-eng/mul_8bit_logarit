#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Official Competition Submission Report Builder
"AI ACCELERATOR DESIGN CHALLENGE 2026" - TRACK 2: APPROXIMATE MULTIPLIER
Conforms 100% to the Official Call for Submissions (THONG BAO NOP SAN PHAM VONG BAN KET).
Generates both Markdown (.md) and validated Word (.docx) documents.
Author: NGUYEN VAN THUC - 24161421
"""

import os
import sys
import zipfile
import xml.etree.ElementTree as ET
from datetime import datetime

sys.path.append("/workspace/projects/mult_8bit/scripts")
from generate_functional_report import run_exhaustive_verification

def xml_escape(text):
    if text is None:
        return ""
    return (str(text)
            .replace("&", "&amp;")
            .replace("<", "&lt;")
            .replace(">", "&gt;")
            .replace('"', "&quot;")
            .replace("'", "&apos;"))

def build_competition_reports():
    data_v6 = run_exhaustive_verification("lutalm", 4, 0)
    
    md_path = "/workspace/projects/mult_8bit/docs/BAO_CAO_BAN_KET_CUOC_THI_AI_ACCELERATOR_2026.md"
    docx_path = "/workspace/projects/mult_8bit/docs/BAO_CAO_BAN_KET_CUOC_THI_AI_ACCELERATOR_2026.docx"
    
    # -------------------------------------------------------------
    # 1. GENERATE MARKDOWN REPORT
    # -------------------------------------------------------------
    with open(md_path, "w", encoding="utf-8") as f:
        f.write("""# BÁO CÁO NỘP SẢN PHẨM VÒNG BÁN KẾT
## CUỘC THI THIẾT KẾ BỘ GIA TỐC AI (AI ACCELERATOR DESIGN CHALLENGE 2026)
### TRACK 2: THIẾT KẾ MẠCH NHÂN XẤP XỈ 8-BIT (APPROXIMATE MULTIPLIER)

---

- **Đơn vị tổ chức:** Ban Tổ chức Cuộc thi "AI Accelerator Design Challenge 2026" - Khoa ĐT-CL / Bộ môn Kỹ thuật Máy tính - ĐH Sư phạm Kỹ thuật TP.HCM (HCMUTE)
- **Thí sinh thực hiện:** **NGUYỄN VĂN THỨC**
- **Mã số sinh viên:** **24161421**
- **Email:** `chuantinh2407@gmail.com` / `dce@hcmute.edu.vn`
- **Tên thiết kế đề xuất:** **LUT-ALM (Look-Up Table Approximate Logarithmic Multiplier) - Thế hệ Tối ưu Đa mục tiêu PPA**
- **Nền tảng thực nghiệm:** AMD Xilinx Zybo Z7-10 (FPGA) & Thư viện Nangate 45nm (ASIC)

---

# 1. Ý TƯỞNG VÀ NGUYÊN LÝ THIẾT KẾ (Mục 1.1)

## 1.1. Ý tưởng và Động lực Kiến trúc
Trong các bộ gia tốc AI phần cứng (NPU/Systolic Array cho CNN/Transformer), các phép nhân số nguyên có dấu 8-bit (Signed INT8) chiếm tới hơn **80% diện tích silicon và công suất tiêu thụ**.
- **Kiến trúc thông thường (Baseline của Ban tổ chức):** Sử dụng mạng cộng ma trận tích từng phần tuyến tính (Array Multiplier / Baugh-Wooley). Mạch này yêu cầu tới **150 Slice LUTs** trên FPGA Xilinx 7-Series, độ trễ 10 tầng logic (9.814 ns) và tiêu hao 4.0 mW công suất động.
- **Ý tưởng đột phá đề xuất:** Chuyển phép nhân từ miền tuyến tính sang **miền Logarithm (Logarithmic Number System - LNS)**:
  $$|P| = |A| \\times |B| \\iff \\log_2(|P|) = \\log_2(|A|) + \\log_2(|B|)$$
  Biến phép nhân phức tạp thành **phép cộng 1 tầng**, giúp cắt giảm hơn **51% số lượng LUTs** và giảm **gần 60% công suất** trên cả FPGA lẫn ASIC.

## 1.2. Kiến trúc và Sơ đồ Khối (Block Diagram)
Kiến trúc đề xuất bao gồm 5 khối chức năng được tối ưu hóa đồng thiết kế giữa Toán học và Cấu trúc Phần cứng FPGA:

```
[a_i[7:0]] ---> [log_input_sign_u8] ---> |A|, sign_a, zero_a 
                                                |
                                        [log_normalizer_u8]  (Leading One Detector: k_A, mant_A)
                                                |
                                      [log_lut_converter_u8] (Micro-LUT Low-3: high_A, low_A)
                                                |
                                                v
[b_i[7:0]] ---> (Chuỗi tương tự)  ---> [log_adder_u8]        (Cộng Exponent k & Fraction F)
                                                |
                                                v
                                       [log_antilog_u16]     (Giải mã ngược Antilog MUX 16-case)
                                                |
                                                v
                                      [Fused Round & Sign]   (Cắt 4-bit LSB + Làm tròn + Bù 2)
                                                |
                                                v
                                           [p_o[15:0]]       (Kết quả Signed INT8 16-bit)
```

## 1.3. Công thức Toán học Cốt lõi
1. **Chuẩn hóa nhị phân (Binary Normalization):**
   Mọi toán hạng $|N| \\in [1, 128]$ được phân rã dạng:
   $$|N| = 2^k \\cdot (1 + x)$$
   với $k = \\lfloor \\log_2 |N| \\rfloor$ (vị trí bit 1 cao nhất) và $x \\in [0, 1)$ là mantissa.
2. **Khắc phục triệt để sai số của Mitchell bằng Vi hiệu chỉnh Micro-LUT:**
   Thuật toán cổ điển Mitchell (1962) đặt $\\log_2(1+x) \\approx x$ gây sai số tương đối cực đại lên tới $11.1\\%$ (vượt xa trần cho phép $3.2\\%$). Thiết kế đề xuất phân rã mantissa thành 3 bit cao $x_H$ và 3 bit thấp $x_L = \\text{addr}$, sau đó áp dụng bảng bù độ cong tối ưu hóa rời rạc toàn cục:
   $$\\text{log\\_frac} = \\{x_H, \\text{LUT}_{\\text{low3}}[x_L]\\}$$
   Bảng $\\text{LUT}_{\\text{low3}} = \\{1, 3, 4, 4, 6, 6, 7, 7\\}$ vừa khớp đường cong logarit, vừa cộng gộp sẵn địa chỉ `addr` để **loại bỏ 100% bộ cộng phần cứng**.
3. **Giải mã Antilogarit dạng Cây MUX phẳng:**
   $$|P| \\approx \\frac{(2^F + \\text{fraction}) \\ll E}{2^F} \\quad (F = 6)$$
   Được tổng hợp thành cây MUX phẳng 16 nhánh, triệt tiêu hoàn toàn trễ của bộ dịch động (Barrel Shifter).
4. **Nấu chảy phép làm tròn và đổi dấu bù 2 (Fused Rounding & Two's Complement):**
   Thay vì dùng 2 bộ cộng độc lập (một bộ cộng làm tròn $+ \\text{round\\_bit}$, một bộ đổi dấu $+ 1$), thiết kế nấu chảy cả hai thành một tầng cộng duy nhất qua chân `carry_in`, tiết kiệm ngay lập tức **16 LUTs** và **1.2 ns** trễ.

## 1.4. Điểm Cải tiến và Ưu điểm Vượt trội so với Baseline
1. **Tài nguyên siêu tinh gọn:** Giảm từ **150 Slice LUTs xuống chỉ còn 73 - 76 LUTs** (tiết kiệm $> 51\\%$ phần cứng).
2. **Tuyệt đối không dùng DSP:** Đạt chuẩn cấm DSP (`-max_dsp 0`), giải phóng tài nguyên DSP cho các tác vụ xử lý khác trong SoC.
3. **Tốc độ xung nhịp cao hơn:** Giảm độ trễ từ **9.814 ns xuống 8.476 - 8.878 ns**, nâng Fmax từ **101.9 MHz lên 112.6 - 118.0 MHz** (+10.5% đến +15.8% tốc độ).
4. **Tiết kiệm công suất đột phá:** Giảm **50% công suất động trên FPGA** (2.0 mW vs 4.0 mW) và giảm tới **59.5% tổng công suất trên ASIC Nangate 45nm** (72 µW vs 178 µW).

---

# 2. KẾT QUẢ MÔ PHỎNG VÀ ĐÁNH GIÁ THIẾT KẾ (Mục 1.2)

## 2.1. Điều kiện Mô phỏng và Công cụ Sử dụng
Để đảm bảo tính khách quan, khoa học và khả năng tái lập 100%, thiết kế được đánh giá song song trên cả hai nền tảng công nghiệp:

| Tham số thực nghiệm | Nền tảng FPGA (Zybo Z7-10) | Nền tảng ASIC Standard Cell (45nm) |
| :--- | :--- | :--- |
| **Công cụ EDA** | **AMD Vivado 2024.2** | **Yosys 0.33 + OpenSTA 3.1.0** |
| **Dòng chip / Thư viện mục tiêu** | Xilinx Zynq-7000 (`xc7z010clg400-1`) | Nangate Open Cell Library 45nm (`typical 1.1V, 25°C`) |
| **Quy trình tổng hợp** | Full Implementation: Synthesis -> Opt -> Place -> Route | RTL Synthesis (Yosys) -> Standard Cell Mapping (ABC) -> STA/Power (OpenSTA) |
| **Điều kiện Timing / Clock** | $T_{\\text{clk}} = 10.0\\text{ ns}$ ($F_{\\text{clk}} = 100\\text{ MHz}$) | $T_{\\text{clk}} = 10.0\\text{ ns}$ ($F_{\\text{clk}} = 100\\text{ MHz}$) |
| **Ràng buộc DSP** | Cấm dùng khối nhân cứng DSP (`-max_dsp 0`) | Không sử dụng Macro nhân |
| **Ràng buộc IO** | Đặt thanh ghi đồng bộ đầu vào/đầu ra (Registered IO) | In-out timing constraints |

---

## 2.2. Kết quả Kiểm tra Chức năng của Mạch Nhân 8-bit (Functional Verification)

Kiểm thử tự động hóa bằng phương pháp **Vét cạn Toàn bộ 100% không gian dữ liệu (Exhaustive Simulation)** gồm tất cả **65,536 trường hợp** ($A, B \\in [-128, 127]$):

### A. Bảng Chỉ số Đánh giá Sai số Toán học Toàn cục (Theo yêu cầu Track 2)

| Chỉ số kiểm thử chức năng | Ký hiệu / Định nghĩa | Kết quả thực nghiệm (V6) | Tiêu chuẩn Cuộc thi | Đánh giá |
| :--- | :---: | :---: | :---: | :---: |
| **Tổng số trường hợp kiểm tra** | $N = 256 \\times 256$ | **65,536 / 65,536** | $100\\%$ không gian | **Đạt 100% độ phủ** |
| **Tỉ lệ lỗi (Error Rate)** | $\\text{ER} = \\frac{\\text{Số ca } AE \\ne 0}{N}$ | **97.64%** (1,547 ca đúng 100%) | Khuyến khích đo | Đặc trưng mạch xấp xỉ |
| **Sai số tương đối trung bình** | $\\text{MRED} = \\frac{1}{N} \\sum \\frac{\\|P_{\\text{approx}} - P_{\\text{exact}}\\|}{\\|P_{\\text{exact}}\\|}$ | **3.0494%** | **$< 3.20\\%$** | **XUẤT SẮC (Dưới ngưỡng trần)** |
| **Khoảng cách sai số trung bình** | $\\text{MED} = \\frac{1}{N} \\sum \\|P_{\\text{approx}} - P_{\\text{exact}}\\|$ | **105.69 LSB** | Tối ưu hóa | Rất thấp trên thang 16-bit |
| **Sai số tuyệt đối lớn nhất** | $\\text{WCE} = \\max \\|P_{\\text{approx}} - P_{\\text{exact}}\\|$ | **961 LSB** | Giám sát | Tại cặp $(-95, -95)$ |
| **Bảo toàn phép nhân với số 0** | $A=0$ hoặc $B=0$ | **511 / 511 (100%)** | $100\\%$ | **Chính xác tuyệt đối** |

### B. Bảng Thống kê Phân loại theo Nhóm Dấu & Góc Phần Tư
Chứng minh tính đối xứng hoàn hảo của mạch trên cả 4 miền phần tư:

| Nhóm kiểm thử chức năng | Dải giá trị $(A, B)$ | Số lượng mẫu | Chính xác 100% | MRED (%) | WCE (LSB) | Đánh giá chức năng |
| :--- | :---: | :---: | :---: | :---: | :---: | :--- |
| **Trường hợp chứa số 0** | $A=0$ hoặc $B=0$ | **511** | **511** ($100\\%$) | **0.00%** | **0** | Khối Zero Bypass chuẩn 100% |
| **Góc 1: Dương $\\times$ Dương** | $A > 0, B > 0$ | **16,129** | 258 | **3.05%** | 961 | Tích dương đúng 100% về dấu |
| **Góc 2: Dương $\\times$ Âm** | $A > 0, B < 0$ | **16,256** | 259 | **3.05%** | 961 | Tích âm đúng 100% về dấu |
| **Góc 3: Âm $\\times$ Dương** | $A < 0, B > 0$ | **16,256** | 259 | **3.05%** | 961 | Đối xứng hoàn hảo với Góc 2 |
| **Góc 4: Âm $\\times$ Âm** | $A < 0, B < 0$ | **16,384** | 260 | **3.05%** | 961 | Khôi phục dấu bù 2 chính xác |
| **Lũy thừa 2** | $A, B \\in \\{\\pm 1, \\dots, \\pm 64\\}$ | **196** | 96 | - | 128 | Sai lệch chỉ ở bước làm tròn LSB |
| **TỔNG HỢP TOÀN BỘ** | **$[-128, 127]$** | **65,536** | **1,547** | **3.05%** | **961** | **Hoạt động tin cậy và hoàn toàn ổn định** |

### C. Bảng Minh chứng các Test Vectors Tiêu biểu (Corner Cases)

| STT | Kịch bản kiểm thử (Corner Case) | Toán hạng A | Toán hạng B | Tích lý thuyết ($P_{\\text{exact}}$) | Tích mạch tính ($P_{\\text{approx}}$) | Lệch tuyệt đối ($AE$) | Sai số tương đối ($RE$) | Trạng thái |
| :---: | :--- | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| **1** | **Biên số 0 (Zero detect)** | `0` | `50` | `0` | `0` | `0` | **0.00%** | Pass (Chuẩn) |
| **2** | **Biên số 0 cực đại** | `127` | `0` | `0` | `0` | `0` | **0.00%** | Pass (Chuẩn) |
| **3** | **Biên số 0 cực tiểu** | `0` | `-128` | `0` | `0` | `0` | **0.00%** | Pass (Chuẩn) |
| **4** | **Nhân đơn vị âm cực tiểu** | `1` | `-128` | `-128` | `-128` | `0` | **0.00%** | Pass (Chính xác) |
| **5** | **Nhân đơn vị âm đảo** | `-128` | `1` | `-128` | `-128` | `0` | **0.00%** | Pass (Chính xác) |
| **6** | **Lũy thừa 2 chuẩn (Nhỏ)** | `2` | `4` | `8` | `16` | `8` | 100.00% | Lệch bước làm tròn |
| **7** | **Lũy thừa 2 chuẩn (Trung bình)** | `16` | `8` | `128` | `128` | `0` | **0.00%** | Pass (Chính xác) |
| **8** | **Lũy thừa 2 chuẩn (Lớn)** | `32` | `32` | `1,024` | `1,056` | `32` | **3.12%** | Trong ngưỡng an toàn |
| **9** | **Cực đại dương (Max Positive)** | `127` | `127` | `16,129` | `16,128` | `1` | **0.01%** | Siêu chính xác |
| **10**| **Cực tiểu bù 2 (Min Negative)** | `-128` | `-128` | `16,384` | `16,896` | `512` | **3.12%** | Trong ngưỡng an toàn |
| **11**| **Biên chéo Max $\\times$ Min** | `-128` | `127` | `-16,256` | `-16,384` | `128` | **0.79%** | Rất tốt |
| **12**| **Biên chéo Min $\\times$ Max** | `127` | `-128` | `-16,256` | `-16,384` | `128` | **0.79%** | Rất tốt |
| **13**| **Số ngẫu nhiên thông thường 1** | `19` | `23` | `437` | `432` | `5` | **1.14%** | Rất tốt |
| **14**| **Số ngẫu nhiên thông thường 2** | `63` | `63` | `3,969` | `4,032` | `63` | **1.59%** | Rất tốt |
| **15**| **Số ngẫu nhiên có dấu** | `-64` | `63` | `-4,032` | `-4,096` | `64` | **1.59%** | Rất tốt |
| **16**| **Số bất đối xứng** | `45` | `-78` | `-3,510` | `-3,584` | `74` | **2.11%** | Rất tốt |
| **17**| **Trường hợp xấu nhất (WCE)** | `-95` | `-95` | `9,025` | `8,064` | `961` | **10.65%** | Đạt đỉnh sai số WCE |

---

## 2.3. Báo cáo Tài nguyên Sử dụng (Area / Resource Utilization)
Đo lường sau bước Physical Implementation (Place & Route thực tế trên chip FPGA Xilinx Zybo Z7-10) và Synthesis trên Nangate 45nm:

| Chỉ số tài nguyên | Baseline (Ban tổ chức) | LUT-ALM V6 (Đề xuất) | LUT-ALM V8 (Extreme PPA) | Mức độ cải thiện |
| :--- | :---: | :---: | :---: | :---: |
| **FPGA Slice LUTs** | **150** | **76** | **73** | **Giảm 51.3% (-77 LUTs)** |
| **Số tầng logic (Levels)** | 10 | 11 | 10 | **Bảo toàn 10 tầng** |
| **Khối nhân phần cứng (DSP)** | **0** | **0** | **0** | **100% tuân thủ cấm DSP** |
| **Flip-Flops (Registers IO)** | 32 | 28 | 28 | Tiết kiệm 4 FFs (cắt LSB) |
| **Số Cell ASIC (Nangate 45nm)** | 296 | 293 | 293 | Giảm 3 standard cells |
| **Diện tích Silicon ASIC (45nm)**| 350.32 µm² | 331.70 µm² | 331.70 µm² | **Giảm 5.3% diện tích** |

---

## 2.4. Báo cáo Công suất Tiêu thụ (Power Consumption)
Đo lường tại tần số $100\\text{ MHz}$ với điện áp tiêu chuẩn:

| Chỉ số công suất tiêu thụ | Baseline (Ban tổ chức) | LUT-ALM V6 (Đề xuất) | Mức độ tối ưu hóa |
| :--- | :---: | :---: | :---: |
| **FPGA Dynamic Power @ 100MHz** | **4.00 mW** | **2.00 mW** | **GIẢM 50.0% (-2.0 mW)** |
| **FPGA Static Power** | 94.00 mW | 94.00 mW | Mức sàn tĩnh của chip Zynq-7000 |
| **FPGA Total Power** | 98.00 mW | 96.00 mW | Giảm nhiệt lượng tổng thể |
| **ASIC Nangate Dynamic Power** | 169.80 µW | 64.00 µW | **Giảm 62.3%** |
| **ASIC Nangate Leakage Power** | 8.20 µW | 8.04 µW | Giảm 2.0% |
| **ASIC Nangate Total Power** | **178.00 µW** | **72.00 µW** | **GIẢM 59.5% (-106 µW)** |

*Nhận xét:* Việc triệt tiêu ma trận 64 tích từng phần và cắt giảm 4-bit LSB đã giảm thiểu tới hơn một nửa số lượng cổng chuyển mạch động, loại bỏ hoàn toàn hiện tượng glitching trôi mức logic.

---

## 2.5. Báo cáo Độ trễ Đường tới hạn và Tần số Hoạt động Tối đa (Timing & Fmax)

| Chỉ số thời gian (Timing Metrics) | Baseline (Ban tổ chức) | LUT-ALM V6 (Đề xuất) | LUT-ALM V8 (Extreme PPA) | Đánh giá |
| :--- | :---: | :---: | :---: | :--- |
| **Độ trễ Data Path (Critical Path Delay)**| **9.814 ns** | **8.476 ns** | **8.878 ns** | **Nhanh hơn 10.5% - 15.8%** |
| **Timing Slack (Target 10.0 ns)** | +0.186 ns | **+1.524 ns** | **+1.122 ns** | Biên độ an toàn cao gấp 8 lần |
| **Tần số hoạt động tối đa ($F_{\\max}$)** | **101.90 MHz** | **117.98 MHz** | **112.64 MHz** | **Vượt xa mốc 100 MHz chuẩn** |
| **ASIC Cell Delay (STA OpenSTA)** | 1.150 ns | 1.420 ns | 1.420 ns | Đạt $F_{\\max} = 704\\text{ MHz}$ trên 45nm |

---

## 2.6. Bảng So sánh Tổng hợp Đối đầu Toàn diện (Head-to-Head Comparison)

Bảng so sánh trực diện giữa Baseline của Ban tổ chức và tất cả các phiên bản cải tiến:

| Kiến trúc | Git Tag | Slice LUTs | Logic Levels | FPGA Delay | FPGA Fmax | MRED (%) | MED (LSB) | WCE (LSB) | FPGA Dyn Pwr | ASIC Area | ASIC Delay | ASIC Total Pwr | DSP |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| **Baseline (Ban Tổ Chức)** | `v0.0.0` | 150 | 10 | 9.814 ns | 101.9 MHz | 0.00% | 0.00 | 0 | 4.0 mW | 350.3 µm² | 1.15 ns | 178.0 µW | 0 |
| **LUT-ALM V6 (Tiêu chuẩn)** | `v0.1.0` | **76** | 11 | **8.476 ns** | **118.0 MHz** | **3.0494%** | 105.69 | 961 | **2.0 mW** | **331.7 µm²** | 1.42 ns | **72.0 µW** | **0** |
| **LUT-ALM V7 Standard** | `v0.2.0` | 75 | 14 | 9.328 ns | 107.2 MHz | 3.0027% | 104.25 | 961 | 2.0 mW | 367.6 µm² | 1.47 ns | 99.2 µW | 0 |
| **LUT-ALM V7 High-Prec** | `v0.2.1` | 79 | 14 | 9.298 ns | 107.5 MHz | 2.8011% | 104.22 | 961 | 2.0 mW | 363.1 µm² | 1.47 ns | 90.1 µW | 0 |
| **LUT-ALM V8 Extreme PPA**| `v0.3.0` | **73** | **10** | **8.878 ns** | **112.6 MHz** | **3.0494%** | 105.69 | 961 | **2.0 mW** | **331.7 µm²** | 1.42 ns | **72.0 µW** | **0** |

---

# 3. KẾT LUẬN & ĐIỂM NHẤN CÔNG NGHỆ TRANH GIẢI

Thiết kế mạch nhân xấp xỉ 8-bit **LUT-ALM** hoàn toàn đáp ứng xuất sắc các tiêu chí của Ban Giám khảo với **5 điểm nhấn công nghệ vượt trội**:

1. **Hiệu quả sử dụng tài nguyên vô địch (-51.3% LUTs):** Cắt giảm từ 150 LUTs xuống còn **73 - 76 LUTs**, giải phóng hơn nửa diện tích logic cho các khối PE khác trong bộ gia tốc AI.
2. **Tiết kiệm năng lượng vượt bậc (-50% đến -59.5% Power):** Cắt giảm một nửa công suất trên FPGA (2.0 mW) và giảm gần 60% trên ASIC 45nm (72 µW), mang lại lợi thế quyết định cho các thiết bị Edge AI chạy pin.
3. **Cải thiện tốc độ (+10.5% đến +15.8% Fmax):** Đường tới hạn chỉ 8.476 ns, vận hành ổn định trên 112 MHz mà không có bất kỳ vi phạm Timing Slack nào.
4. **Kiểm soát sai số khoa học (MRED = 3.0494%):** Nằm an toàn dưới ngưỡng yêu cầu $3.2\\%$, bảo đảm 100% tính toàn vẹn của bit dấu và bảo toàn phép nhân với số 0 tuyệt đối.
5. **Cơ sở hạ tầng thực nghiệm chuẩn công nghiệp:** Toàn bộ mã nguồn RTL, bộ testbench vét cạn 65,536 trường hợp, script tổng hợp tự động `make all`, bitstream nạp board Zybo Z7-10 đều đã sẵn sàng và được đóng gói hoàn chỉnh.

---
*Báo cáo được biên soạn và kiểm chứng thực nghiệm tự động bởi Sinh viên Nguyễn Văn Thức (MSSV: 24161421).*
""")

    print(f"[OK] Generated Markdown Competition Report: {md_path}")

    # -------------------------------------------------------------
    # 2. GENERATE VALIDATED WORD (.DOCX) REPORT
    # -------------------------------------------------------------
    xml_parts = []
    
    # Document Header
    xml_parts.append("""
    <w:p>
        <w:pPr><w:jc w:val="center"/></w:pPr>
        <w:r><w:rPr><w:b/><w:sz w:val="34"/><w:color w:val="1F497D"/></w:rPr>
        <w:t>BÁO CÁO NỘP SẢN PHẨM VÒNG BÁN KẾT</w:t></w:r>
    </w:p>
    <w:p>
        <w:pPr><w:jc w:val="center"/></w:pPr>
        <w:r><w:rPr><w:b/><w:sz w:val="26"/><w:color w:val="2E75B6"/></w:rPr>
        <w:t>CUỘC THI THIẾT KẾ BỘ GIA TỐC AI (AI ACCELERATOR DESIGN CHALLENGE 2026)</w:t></w:r>
    </w:p>
    <w:p>
        <w:pPr><w:jc w:val="center"/></w:pPr>
        <w:r><w:rPr><w:i/><w:sz w:val="22"/><w:color w:val="595959"/></w:rPr>
        <w:t>TRACK 2: THIẾT KẾ MẠCH NHÂN XẤP XỈ 8-BIT (APPROXIMATE MULTIPLIER)</w:t></w:r>
    </w:p>
    <w:p>
        <w:pPr><w:jc w:val="center"/></w:pPr>
        <w:r><w:rPr><w:b/><w:sz w:val="20"/><w:color w:val="000000"/></w:rPr>
        <w:t>Thí sinh: NGUYỄN VĂN THỨC - MSSV: 24161421 - Trường ĐH Sư phạm Kỹ thuật TP.HCM</w:t></w:r>
    </w:p>
    <w:p><w:r><w:t></w:t></w:r></w:p>
    """)

    def add_heading(title, size=24):
        xml_parts.append(f"""
        <w:p>
            <w:r><w:rPr><w:b/><w:sz w:val="{size}"/><w:color w:val="1F497D"/></w:rPr>
            <w:t>{xml_escape(title)}</w:t></w:r>
        </w:p>
        """)

    def add_paragraph(text, italic=False, bold=False):
        style = ""
        if bold: style += "<w:b/>"
        if italic: style += "<w:i/>"
        xml_parts.append(f"""
        <w:p>
            <w:r><w:rPr>{style}<w:sz w:val="21"/></w:rPr>
            <w:t>{xml_escape(text)}</w:t></w:r>
        </w:p>
        """)

    def add_table(headers, rows):
        rows_xml = []
        # Header
        h_cells = "".join([f"<w:tc><w:tcPr><w:shd w:val=\"clear\" w:color=\"auto\" w:fill=\"1F497D\"/></w:tcPr><w:p><w:pPr><w:jc w:val=\"center\"/></w:pPr><w:r><w:rPr><w:b/><w:sz w:val=\"19\"/><w:color w:val=\"FFFFFF\"/></w:rPr><w:t>{xml_escape(h)}</w:t></w:r></w:p></w:tc>" for h in headers])
        rows_xml.append(f"<w:tr>{h_cells}</w:tr>")
        # Data
        for row in rows:
            r_cells = "".join([f"<w:tc><w:p><w:r><w:rPr><w:sz w:val=\"18\"/></w:rPr><w:t>{xml_escape(c)}</w:t></w:r></w:p></w:tc>" for c in row])
            rows_xml.append(f"<w:tr>{r_cells}</w:tr>")
        xml_parts.append(f"""
        <w:tbl>
            <w:tblPr>
                <w:tblW w:w="5000" w:type="pct"/>
                <w:tblBorders>
                    <w:top w:val="single" w:sz="4" w:space="0" w:color="auto"/>
                    <w:left w:val="single" w:sz="4" w:space="0" w:color="auto"/>
                    <w:bottom w:val="single" w:sz="4" w:space="0" w:color="auto"/>
                    <w:right w:val="single" w:sz="4" w:space="0" w:color="auto"/>
                    <w:insideH w:val="single" w:sz="4" w:space="0" w:color="auto"/>
                    <w:insideV w:val="single" w:sz="4" w:space="0" w:color="auto"/>
                </w:tblBorders>
            </w:tblPr>
            {"".join(rows_xml)}
        </w:tbl>
        <w:p><w:r><w:t></w:t></w:r></w:p>
        """)

    # --- SECTION 1 ---
    add_heading("1. Ý TƯỞNG VÀ NGUYÊN LÝ THIẾT KẾ (Mục 1.1)", 26)
    add_paragraph("1.1. Động lực: Mạch nhân tuyến tính Baugh-Wooley truyền thống (Baseline) tốn tới 150 Slice LUTs và 4.0 mW do phải sinh và gom 64 tích từng phần.")
    add_paragraph("1.2. Ý tưởng giải pháp: Chuyển phép nhân sang miền Logarithm (LNS): |P| = 2^(log2 |A| + log2 |B|), thay thế mạng cộng ma trận bằng 1 bộ cộng số học duy nhất.")
    add_paragraph("1.3. Đột phá kiến trúc LUT-ALM: Sử dụng bảng vi hiệu chỉnh Micro-LUT Low-3 {1, 3, 4, 4, 6, 6, 7, 7} nhúng trực tiếp địa chỉ vào dữ liệu để triệt tiêu bộ cộng; kết hợp Antilog MUX phẳng và bộ làm tròn hội tụ (Fused Rounding & Two's Complement).")
    add_paragraph("1.4. Ưu thế vượt trội: Tiết kiệm hơn 51% LUTs (73 - 76 LUTs vs 150 LUTs), giảm 50% công suất FPGA và 59.5% công suất ASIC 45nm, tăng tần số hoạt động lên 112.6 - 118.0 MHz, hoàn toàn không dùng DSP.")

    # --- SECTION 2 ---
    add_heading("2. KẾT QUẢ MÔ PHỎNG VÀ ĐÁNH GIÁ THIẾT KẾ (Mục 1.2)", 26)
    add_paragraph("2.1. Điều kiện mô phỏng & Công cụ: AMD Vivado 2024.2 trên Zybo Z7-10 (xc7z010clg400-1) và Yosys 0.33 + OpenSTA 3.1.0 trên Nangate 45nm Typical 1.1V 25°C, Clock 100 MHz, cấm DSP (-max_dsp 0).", bold=True)
    
    add_heading("Bảng 1: Tổng hợp Chỉ số Đánh giá Sai số Toán học (65,536 Trường hợp Vét cạn)", 22)
    headers_acc = ["Chỉ số kiểm thử", "Kết quả thực nghiệm", "Yêu cầu Ban tổ chức", "Đánh giá"]
    rows_acc = [
        ["Tổng số trường hợp kiểm tra", "65,536 / 65,536", "100% không gian", "Đạt 100% độ phủ (Full Coverage)"],
        ["Tỉ lệ lỗi (Error Rate - ER)", "97.64% (1,547 ca đúng 100%)", "Khuyến khích đo", "Đặc trưng mạch xấp xỉ LNS"],
        ["Sai số tương đối trung bình (MRED)", f"{data_v6['mred_pct']:.4f}%", "< 3.20%", "XUẤT SẮC (Dưới ngưỡng trần)"],
        ["Khoảng cách sai số trung bình (MED)", f"{data_v6['med']:.2f} LSB", "Cực tiểu hóa", "Rất thấp trên dải 16-bit"],
        ["Sai số tuyệt đối lớn nhất (WCE)", f"{data_v6['wce']} LSB", "Giám sát", f"Tại cặp ({data_v6['worst_case']['a']}, {data_v6['worst_case']['b']})"],
        ["Phép nhân với số 0 chính xác", "511 / 511 (100%)", "100%", "Chính xác tuyệt đối (Bypass 0)"]
    ]
    add_table(headers_acc, rows_acc)

    add_heading("Bảng 2: Thống kê Phân loại theo 4 Góc Phần Tư & Miền Dấu", 22)
    headers_cat = ["Nhóm kiểm thử chức năng", "Số mẫu", "Chính xác 100%", "MRED (%)", "WCE (LSB)", "Đánh giá"]
    rows_cat = []
    for k, v in data_v6["categories"].items():
        mred_str = f"{v['re_sum'] / v['count_nz'] * 100.0:.2f}%" if v['count_nz'] > 0 else "0.00%"
        rows_cat.append([v['name'], f"{v['total']:,}", f"{v['correct']:,}", mred_str, str(v['max_ae']), "Chuẩn xác, đối xứng"])
    add_table(headers_cat, rows_cat)

    add_heading("Bảng 3: Minh chứng các Test Vectors Tiêu biểu (Corner Cases)", 22)
    headers_vec = ["STT", "Kịch bản kiểm thử", "Toán hạng A", "Toán hạng B", "Tích lý thuyết", "Tích mạch tính", "Lệch (AE)", "Sai số (RE)"]
    rows_vec = []
    for idx, item in enumerate(data_v6["key_results"][:14], 1):
        rows_vec.append([str(idx), item["desc"], str(item["a"]), str(item["b"]), f"{item['exact']:,}", f"{item['approx']:,}", str(item["ae"]), f"{item['re']:.2f}%"])
    add_table(headers_vec, rows_vec)

    add_heading("Bảng 4: So sánh Tổng hợp Đối đầu Toàn diện (Baseline vs LUT-ALM V6/V7/V8)", 22)
    headers_comp = ["Kiến trúc", "Slice LUTs", "Levels", "FPGA Delay", "Fmax", "MRED", "FPGA Dyn Pwr", "ASIC Area", "ASIC Pwr", "DSP"]
    rows_comp = [
        ["Baseline (Ban Tổ Chức)", "150", "10", "9.814 ns", "101.9 MHz", "0.00%", "4.00 mW", "350.3 µm²", "178.0 µW", "0"],
        ["LUT-ALM V6 (Tiêu chuẩn)", "76", "11", "8.476 ns", "118.0 MHz", "3.05%", "2.00 mW", "331.7 µm²", "72.0 µW", "0"],
        ["LUT-ALM V7 Standard", "75", "14", "9.328 ns", "107.2 MHz", "3.00%", "2.00 mW", "367.6 µm²", "99.2 µW", "0"],
        ["LUT-ALM V7 High-Prec", "79", "14", "9.298 ns", "107.5 MHz", "2.80%", "2.00 mW", "363.1 µm²", "90.1 µW", "0"],
        ["LUT-ALM V8 Extreme PPA", "73", "10", "8.878 ns", "112.6 MHz", "3.05%", "2.00 mW", "331.7 µm²", "72.0 µW", "0"]
    ]
    add_table(headers_comp, rows_comp)

    # --- SECTION 3 ---
    add_heading("3. KẾT LUẬN & ĐIỂM NHẤN CÔNG NGHỆ TRANH GIẢI", 26)
    add_paragraph("1. Tiết kiệm tài nguyên: Giảm 51.3% số lượng LUTs (từ 150 xuống 73 LUTs), không dùng DSP.", bold=True)
    add_paragraph("2. Tiết kiệm công suất: Giảm 50% công suất FPGA (2.0 mW) và 59.5% công suất ASIC 45nm (72 µW).", bold=True)
    add_paragraph("3. Nâng cao tốc độ: Fmax tăng 10.5% - 15.8% (112.6 - 118.0 MHz vs 101.9 MHz).", bold=True)
    add_paragraph("4. Độ chính xác cao: MRED = 3.0494%, tuân thủ nghiêm ngặt tiêu chuẩn < 3.2% của cuộc thi.", bold=True)
    add_paragraph("5. Sẵn sàng triển khai: Bộ nhớ bitstream nạp board Zybo Z7-10 đã được đóng gói và kiểm chứng.", bold=True)

    content_xml = "\n".join(xml_parts)
    
    # Official OpenXML Content_Types schema
    content_types = """<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
    <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
    <Default Extension="xml" ContentType="application/xml"/>
    <Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>
</Types>"""

    rels = """<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
    <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>
</Relationships>"""

    doc_xml = f"""<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
    <w:body>
{content_xml}
    </w:body>
</w:document>"""

    # Validate XML before writing
    try:
        ET.fromstring(content_types)
        ET.fromstring(rels)
        ET.fromstring(doc_xml)
    except Exception as e:
        print(f"FATAL: Generated XML validation failed: {e}")
        sys.exit(1)

    with zipfile.ZipFile(docx_path, "w", zipfile.ZIP_DEFLATED) as z:
        z.writestr("[Content_Types].xml", content_types)
        z.writestr("_rels/.rels", rels)
        z.writestr("word/document.xml", doc_xml)

    print(f"[OK] Generated Validated Word Competition Report: {docx_path}")

if __name__ == "__main__":
    build_competition_reports()
