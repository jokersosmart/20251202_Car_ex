# 實現任務清單：SSD 控制器電源管理安全功能

**Feature**: 001-Power-Management-Safety  
**Feature Name**: SSD Controller Power Management Safety Feature  
**ASIL Level**: ASIL-B  
**Date**: 2025-12-03  
**Status**: READY FOR IMPLEMENTATION  

---

## 執行摘要

基於完整的 Phase 0 研究、功能規格 (spec.md) 和實現計畫 (plan.md)，本任務清單涵蓋 Phase 2 實現的所有工作項。任務按安全目標組織，支持獨立驗收和並行實現。

### 任務統計

| 階段 | 任務數 | 故事數 | 並行機會 | 預計耗時 |
|------|--------|--------|---------|----------|
| Phase 1: Setup | 6 | N/A | 3 | 2 天 |
| Phase 2: Foundational | 8 | N/A | 4 | 2 天 |
| Phase 3: Power Safety (US1) | 12 | 1 | 5 | 4 天 |
| Phase 4: Clock Safety (US2) | 10 | 1 | 4 | 3 天 |
| Phase 5: Memory Safety (US3) | 11 | 1 | 5 | 3 天 |
| Phase 6: Fault Management (US4) | 9 | 1 | 3 | 2 天 |
| Phase 7: Polish & Cross-Cutting | 7 | N/A | 2 | 2 天 |
| **總計** | **63** | **4** | **26** | **18 天** |

### 用户故事优先级和依赖

```
優先級 1 (P1):
├─ US1: Power Supply Monitoring & Safe-State Handling (電源供應監控)
└─ US2: Clock Loss Detection & Response (時鐘丟失檢測)

優先級 2 (P2):
├─ US3: Memory ECC Protection & Diagnostics (記憶體 ECC 保護)
└─ US4: Fault Aggregation & System Recovery (故障聚合與恢復)

依賴流：
Setup → Foundational → US1, US2 (並行) → US3, US4 (並行)
```

---

## Phase 1: 項目設置與基礎架構

**目標**: 配置開發環境、建立代碼框架、整合工具鏈  
**獨立驗收**: 代碼庫已準備好，所有工具可運行  
**預計時間**: 2 天

### 1.1 代碼庫和分支初始化

- [ ] T001 初始化 Git 項目結構並切換到 001-power-management-safety 分支
  - 位置：[.git](../../../.git), [.gitignore](../../../.gitignore)
  - 驗收標準：分支已創建，.gitignore 包含 build/, *.o, *.so, .vscode

- [ ] T002 [P] 創建 RTL 目錄結構 (power_monitor, clock_monitor, memory_protection, top_level)
  - 位置：[rtl/](../../../rtl/)
  - 驗收標準：4 個子目錄已創建，每個目錄有 .gitkeep

- [ ] T003 [P] 創建固件目錄結構 (src/, tests/, include/)
  - 位置：[firmware/](../../../firmware/)
  - 驗收標準：3 個主目錄已創建，tests 包含 unit/, integration/, coverage/

- [ ] T004 [P] 創建驗證/UVM 目錄結構 (testbench/, agents/, tests/, coverage/)
  - 位置：[verification/](../../../verification/)
  - 驗收標準：4 個子目錄已創建，包含示例 .sv 文件

### 1.2 工具鏈和依賴項安装

- [ ] T005 安裝并驗證 Verilator (用於 RTL 模擬) 和 GCC/Python 環境
  - 位置：[.specify/scripts/](../../../.specify/scripts/)
  - 驗收標準：`verilator --version` 和 `gcc --version` 正常輸出

- [ ] T006 [P] 配置 pytest、gcov、Lizard、cppcheck 進行代碼分析和測試
  - 位置：[firmware/requirements.txt](../../../firmware/requirements.txt)
  - 驗收標準：requirements.txt 包含所有 4 個工具，`pip install -r` 成功

---

## Phase 2: 基礎設施和共用組件

**目標**: 實現所有故事的共同依賴 (HAL、中斷機制、狀態機框架)  
**獨立驗收**: HAL 層可編譯，ISR 框架可測試，狀態機可驗證  
**預計時間**: 2 天

### 2.1 硬體抽象層 (HAL) 實現

- [ ] T007 創建中斷向量表和異常處理程序
  - 位置：[firmware/src/hal/interrupt_handler.c](../../../firmware/src/hal/interrupt_handler.c)
  - 驗收標準：
    - 文件包含 fault_isr_entry() 入口函數
    - 支持 3 個故障源 (VDD_ISR, CLK_ISR, MEM_ISR)
    - 中斷延遲 < 5μs (根據 TSR-002)

- [ ] T008 [P] 實現電源控制 API (power_init, power_get_status, power_enter_safe_state)
  - 位置：[firmware/src/hal/power_api.c](../../../firmware/src/hal/power_api.c)
  - 驗收標準：
    - 3 個公開函數已實現
    - 安全狀態進入延遲 < 10ms
    - 無 malloc/free 調用

### 2.2 共享數據結構和類型定義

- [ ] T009 定義安全狀態標誌和故障代碼枚舉
  - 位置：[firmware/include/safety_types.h](../../../firmware/include/safety_types.h)
  - 驗收標準：
    - 包含 safety_status_t, fault_statistics_t, recovery_config_t 結構
    - 包含 fault_type_t 和 recovery_result_t 枚舉
    - 所有標誌使用 volatile 聲明

- [ ] T010 [P] 實現故障狀態機框架 (初始化、狀態轉遷、查詢接口)
  - 位置：[firmware/src/safety/safety_fsm.c](../../../firmware/src/safety/safety_fsm.c)
  - 驗收標準：
    - 包含 fsm_init(), fsm_transition(), fsm_get_state() 函數
    - 支持 5 個狀態 (INIT, NORMAL, FAULT, SAFE_STATE, RECOVERY)
    - 轉遷規則 100% 正確性測試通過

### 2.3 故障聚合和統計

- [ ] T011 實現故障標誌聚合邏輯
  - 位置：[firmware/src/safety/fault_aggregator.c](../../../firmware/src/safety/fault_aggregator.c)
  - 驗收標準：
    - fault_aggregate() 函數支持聚合 3 個故障源
    - 優先級處理已定義
    - 無競態條件（atomic 操作）

- [ ] T012 [P] 實現故障統計收集和診斷覆蓋計算
  - 位置：[firmware/src/safety/fault_statistics.c](../../../firmware/src/safety/fault_statistics.c)
  - 驗收標準：
    - 支持按故障類型計數
    - get_fault_statistics() 返回 fault_statistics_t
    - DC 計算函數已實現

### 2.4 基礎單元測試

- [ ] T013 為狀態機框架編寫單元測試
  - 位置：[firmware/tests/unit/test_safety_fsm.py](../../../firmware/tests/unit/test_safety_fsm.py)
  - 驗收標準：
    - 25 個測試用例覆蓋所有狀態轉遷
    - SC ≥ 100%, BC ≥ 100%
    - 所有測試通過

- [ ] T014 [P] 為故障聚合邏輯編寫單元測試
  - 位置：[firmware/tests/unit/test_fault_aggregator.py](../../../firmware/tests/unit/test_fault_aggregator.py)
  - 驗收標準：
    - 15 個測試用例覆蓋所有故障組合 (3! = 6 個組合 × 2.5)
    - 優先級處理驗證
    - SC ≥ 100%, BC ≥ 100%

---

## Phase 3: 電源供應安全 (US1) - P1 優先級

**用户故事 (US1)**: 作為系統用户，我希望系統能在電源故障時自動進入安全狀態，防止數據丟失  
**驗收標準**:
- VDD 低於 2.7V 時在 100ms 內檢測到故障
- 系統進入預定義安全狀態（停止寫操作、隔離數據匯流排）
- 故障清除後可恢復正常操作
- 檢測延遲 < 1μs, 軟體反應 < 5ms

**預計時間**: 4 天  
**測試驗收**: 獨立測試故事，不依賴其他故事

### 3.1 硬體 VDD 監控電路 (RTL)

- [ ] T015 [P] 實現 VDD 監控比較器和濾波電路 (rc_filter, comparator_wrapper)
  - 位置：[rtl/power_monitor/comparator.v](../../../rtl/power_monitor/comparator.v)
  - 驗收標準：
    - 基準電壓 1.35V (對應 2.7V VDD)
    - 遲滯 ±50mV (防振盪)
    - RC 截止頻率 ~16kHz (根據 research.md Task 5)
    - 檢測延遲 < 50ns

- [ ] T016 [P] 實現 VDD 監控狀態機 (voltage level detection, fault flag generation)
  - 位置：[rtl/power_monitor/vdd_monitor.v](../../../rtl/power_monitor/vdd_monitor.v)
  - 驗收標準：
    - VDD 連續監控
    - 故障檢測邊界 2.65V - 2.75V
    - FAULT_VDD 輸出延遲 < 1μs
    - 複雜度 CC ≤ 10

- [ ] T017 [P] 實現電源時序控制器 (power sequencing, soft/hard reset)
  - 位置：[rtl/power_monitor/supply_sequencer.v](../../../rtl/power_monitor/supply_sequencer.v)
  - 驗收標準：
    - 支持 3 階段電源上升：1V → 2V → 3.3V
    - 每階段延遲可配置
    - 掉電檢測時進入安全狀態

### 3.2 軟體電源監控服務

- [ ] T018 [P] 實現電源監控任務 (power monitoring ISR)
  - 位置：[firmware/src/power/pwr_event_handler.c](../../../firmware/src/power/pwr_event_handler.c)
  - 驗收標準：
    - 在 VDD_FAULT 中斷上觸發
    - ISR 執行時間 < 5μs
    - 設置 fault_flags.pwr_fault
    - 可重入 (支援多個同時中斷)

- [ ] T019 [P] 實現電源狀態機和恢復邏輯
  - 位置：[firmware/src/power/pwr_monitor_service.c](../../../firmware/src/power/pwr_monitor_service.c)
  - 驗收標準：
    - pwr_service_init() 初始化
    - pwr_service_handle_fault() 故障處理
    - pwr_service_request_recovery() 恢復請求
    - 恢復超時 100ms

### 3.3 VDD 硬體驗證 (UVM)

- [ ] T020 [P] 實現 VDD 監控功能測試 UVM 驗證
  - 位置：[verification/testbench/power_monitor_tb.sv](../../../verification/testbench/power_monitor_tb.sv)
  - 驗收標準：
    - 40 個測試用例 (來自 research.md Task 2)
    - SC ≥ 99%, BC ≥ 96.6%
    - 所有電壓掃描通過
    - 遲滯驗證正確

- [ ] T021 [P] 實現 VDD 故障注入測試
  - 位置：[verification/tests/vdd_fault_injection_test.sv](../../../verification/tests/vdd_fault_injection_test.sv)
  - 驗收標準：
    - 36 個 VDD 監控故障 (SA0 + SA1 + Delay)
    - DC 計算 > 90%
    - 所有注入故障被檢測

### 3.4 電源軟體驗證 (pytest)

- [ ] T022 [P] 實現電源監控單元測試
  - 位置：[firmware/tests/unit/test_pwr_monitor.py](../../../firmware/tests/unit/test_pwr_monitor.py)
  - 驗收標準：
    - 20 個單元測試用例
    - 測試 fault flag 設置、清除、查詢
    - SC ≥ 100%, BC ≥ 100%

- [ ] T023 實現電源故障整合測試
  - 位置：[firmware/tests/integration/test_pwr_fault_scenarios.py](../../../firmware/tests/integration/test_pwr_fault_scenarios.py)
  - 驗收標準：
    - 10 個場景測試 (單故障、多故障、優先級)
    - 驗證 ISR → 狀態機 → 恢復流程
    - 計時驗證 (ISR < 5μs, 恢復 < 100ms)

### 3.5 電源文檔和追蹤

- [ ] T024 [P] 為 VDD 監控電路編寫 RTL 設計文檔
  - 位置：[docs/architecture/vdd_monitor_design.md](../../../docs/architecture/vdd_monitor_design.md)
  - 驗收標準：
    - 包含原理圖描述
    - 時序分析
    - 溫度係數漂移分析 (根據 research.md Task 5)

- [ ] T025 [P] 創建電源安全功能的追蹤矩陣
  - 位置：[docs/analysis/traceability_us1.md](../../../docs/analysis/traceability_us1.md)
  - 驗收標準：
    - SG-001 → FSR-001 → SysReq-001 → TSR-001
    - 100% 映射完成
    - 所有測試用例追蹤到需求

---

## Phase 4: 時鐘丟失檢測 (US2) - P1 優先級

**用户故事 (US2)**: 作為系統用户，我希望系統能檢測時鐘丟失並自動進入安全狀態，防止非同步存取  
**驗收標準**:
- 檢測時鐘停止 > 1μs
- 故障檢測延遲 < 100ns
- 軟體反應延遲 < 5ms
- 時鐘恢復後可恢復正常操作

**預計時間**: 3 天  
**可並行執行**: 與 US1 平行 (獨立的故障源)

### 4.1 硬體時鐘監控電路 (RTL)

- [ ] T026 [P] 實現時鐘看門狗計時器 (clock watchdog)
  - 位置：[rtl/clock_monitor/clock_watchdog.v](../../../rtl/clock_monitor/clock_watchdog.v)
  - 驗收標準：
    - 監控 400MHz 主時鐘
    - 停止檢測邊界 > 1μs
    - FAULT_CLK 輸出延遲 < 100ns
    - 複雜度 CC ≤ 10

- [ ] T027 [P] 實現 PLL 健康監控 (frequency out-of-range detection)
  - 位置：[rtl/clock_monitor/pll_monitor.v](../../../rtl/clock_monitor/pll_monitor.v)
  - 驗收標準：
    - 監控 PLL 輸出頻率
    - 頻率範圍檢查 (400MHz ±1%)
    - 失鎖檢測 < 100ns

### 4.2 軟體時鐘監控服務

- [ ] T028 [P] 實現時鐘監控 ISR
  - 位置：[firmware/src/clock/clk_event_handler.c](../../../firmware/src/clock/clk_event_handler.c)
  - 驗收標準：
    - 在 CLK_FAULT 中斷上觸發
    - ISR 執行時間 < 5μs
    - 設置 fault_flags.clk_fault
    - 可重入

- [ ] T029 [P] 實現時鐘恢復邏輯
  - 位置：[firmware/src/clock/clk_monitor_service.c](../../../firmware/src/clock/clk_monitor_service.c)
  - 驗收標準：
    - 檢測時鐘恢復信號
    - 驗證時鐘穩定性 (防止虛報)
    - 恢復序列正確

### 4.3 時鐘硬體驗證 (UVM)

- [ ] T030 [P] 實現時鐘監控功能測試
  - 位置：[verification/testbench/clock_monitor_tb.sv](../../../verification/testbench/clock_monitor_tb.sv)
  - 驗收標準：
    - 24 個測試用例 (來自 research.md Task 2)
    - SC ≥ 100%, BC ≥ 99%
    - 時鐘停止/恢復場景覆蓋

- [ ] T031 [P] 實現時鐘故障注入測試
  - 位置：[verification/tests/clock_fault_injection_test.sv](../../../verification/tests/clock_fault_injection_test.sv)
  - 驗收標準：
    - 24 個時鐘監控故障 (SA0, SA1, Delay)
    - DC > 95%
    - 所有模式被檢測

### 4.4 時鐘軟體驗證 (pytest)

- [ ] T032 [P] 實現時鐘監控單元測試
  - 位置：[firmware/tests/unit/test_clk_monitor.py](../../../firmware/tests/unit/test_clk_monitor.py)
  - 驗收標準：
    - 15 個單元測試
    - 時鐘狀態機 (正常、停止、恢復)
    - SC ≥ 100%, BC ≥ 100%

- [ ] T033 實現時鐘故障整合測試
  - 位置：[firmware/tests/integration/test_clock_fault_scenarios.py](../../../firmware/tests/integration/test_clock_fault_scenarios.py)
  - 驗收標準：
    - 8 個場景 (停止、恢復、低速、噪聲時鐘)
    - 時序驗證
    - 系統恢復驗證

### 4.5 時鐘文檔

- [ ] T034 [P] 編寫時鐘監控電路設計文檔
  - 位置：[docs/architecture/clock_monitor_design.md](../../../docs/architecture/clock_monitor_design.md)
  - 驗收標準：
    - 看門狗計時器設計說明
    - 時序分析
    - 故障檢測邏輯

- [ ] T035 [P] 創建時鐘安全功能的追蹤矩陣
  - 位置：[docs/analysis/traceability_us2.md](../../../docs/analysis/traceability_us2.md)
  - 驗收標準：
    - SG-002 → FSR-002 → SysReq-001 → TSR-002
    - 100% 映射

---

## Phase 5: 記憶體 ECC 保護 (US3) - P2 優先級

**用户故事 (US3)**: 作為系統用户，我希望系統能檢測和糾正記憶體故障，防止資料損毀  
**驗收標準**:
- 單位元故障 (SBE) 自動糾正率 > 99%
- 多位元故障 (MBE) 檢測率 100%
- 故障診斷覆蓋率 > 90%
- 不中斷正常操作

**預計時間**: 3 天  
**可並行執行**: 與 US4 平行 (但 US1/US2 應先完成)

### 5.1 硬體 ECC 引擎 (RTL)

- [ ] T036 [P] 實現 Hamming-SEC/DED ECC 編碼器
  - 位置：[rtl/memory_protection/ecc_encoder.v](../../../rtl/memory_protection/ecc_encoder.v)
  - 驗收標準：
    - 生成 ECC 位 (根據 Hamming 碼)
    - 延遲 < 100ns
    - 面積 < 500 LUT

- [ ] T037 [P] 實現 ECC 檢測和糾正邏輯 (ECC EDAC)
  - 位置：[rtl/memory_protection/ecc_decoder.v](../../../rtl/memory_protection/ecc_decoder.v)
  - 驗收標準：
    - 檢測並糾正單位元錯誤 (SBE)
    - 檢測多位元錯誤 (MBE) 無法糾正
    - 輸出 error_flag 和 correction_syndrome

- [ ] T038 [P] 實現 ECC 管理控制器 (ECC enable/disable, error interrupt)
  - 位置：[rtl/memory_protection/ecc_controller.v](../../../rtl/memory_protection/ecc_controller.v)
  - 驗收標準：
    - 配置寄存器 (ECC_CTRL)
    - 錯誤統計寄存器 (SBE_COUNT, MBE_COUNT)
    - 中斷生成 (mem_fault 信號)

### 5.2 軟體 ECC 管理服務

- [ ] T039 [P] 實現 ECC 初始化和配置函數
  - 位置：[firmware/src/memory/ecc_service.c](../../../firmware/src/memory/ecc_service.c)
  - 驗收標準：
    - ecc_init() 啟用 ECC
    - ecc_configure(threshold) 設置 SBE/MBE 閾值
    - 無 malloc 調用

- [ ] T040 [P] 實現 ECC 故障事件處理 (SBE/MBE ISR)
  - 位置：[firmware/src/memory/ecc_handler.c](../../../firmware/src/memory/ecc_handler.c)
  - 驗收標準：
    - 在 MEM_FAULT 中斷上觸發
    - 識別 SBE 或 MBE
    - SBE 自動糾正, MBE 上報
    - ISR 執行時間 < 5μs

### 5.3 記憶體硬體驗證 (UVM)

- [ ] T041 [P] 實現 ECC 功能測試
  - 位置：[verification/testbench/memory_protection_tb.sv](../../../verification/testbench/memory_protection_tb.sv)
  - 驗收標準：
    - 50 個測試用例 (SBE, MBE, 邊界)
    - SC ≥ 100%, BC ≥ 99%
    - 糾正效率驗證

- [ ] T042 [P] 實現 ECC 故障注入測試
  - 位置：[verification/tests/ecc_fault_injection_test.sv](../../../verification/tests/ecc_fault_injection_test.sv)
  - 驗收標準：
    - 位翻轉故障注入 (20 個)
    - ECC 硬體故障 (15 個)
    - DC > 95%

### 5.4 記憶體軟體驗證 (pytest)

- [ ] T043 [P] 實現 ECC 服務單元測試
  - 位置：[firmware/tests/unit/test_ecc_service.py](../../../firmware/tests/unit/test_ecc_service.py)
  - 驗收標準：
    - 20 個測試 (初始化、配置、故障)
    - ECC 演算法驗證
    - SC ≥ 100%, BC ≥ 100%

- [ ] T044 實現記憶體故障整合測試
  - 位置：[firmware/tests/integration/test_memory_fault_scenarios.py](../../../firmware/tests/integration/test_memory_fault_scenarios.py)
  - 驗收標準：
    - 15 個場景 (SBE, MBE, 連續故障)
    - 自動糾正驗證
    - 聚合邏輯驗證

### 5.5 記憶體文檔

- [ ] T045 [P] 編寫 ECC 硬體設計文檔
  - 位置：[docs/architecture/ecc_engine_design.md](../../../docs/architecture/ecc_engine_design.md)
  - 驗收標準：
    - Hamming 碼設計詳解
    - SBE/MBE 檢測邏輯
    - 硬體複雜度分析

- [ ] T046 [P] 創建記憶體安全功能的追蹤矩陣
  - 位置：[docs/analysis/traceability_us3.md](../../../docs/analysis/traceability_us3.md)
  - 驗收標準：
    - SG-003 → FSR-003 → SysReq-001 → TSR-???
    - 100% 映射 (注意 FSR-003 無直接 TSR)

---

## Phase 6: 故障聚合與系統恢復 (US4) - P2 優先級

**用户故事 (US4)**: 作為系統，我希望故障聚合器能監控所有故障源並協調系統恢復  
**驗收標準**:
- 聚合 3 個故障源 (VDD, CLK, MEM) 無遺漏
- 優先級處理定義清晰
- 恢復流程完整且無死鎖
- 狀態轉遷覆蓋率 100%

**預計時間**: 2 天  
**可並行執行**: 與 US3 平行 (但 US1/US2 應先完成)

### 6.1 故障聚合和優先級處理

- [ ] T047 [P] 優化故障聚合邏輯 (多故障場景)
  - 位置：[firmware/src/safety/fault_aggregator.c](../../../firmware/src/safety/fault_aggregator.c) [更新]
  - 驗收標準：
    - 支持 3! = 6 種故障組合
    - 優先級定義：VDD_FAULT (P=1) > CLK_FAULT (P=2) > MEM_FAULT (P=3)
    - 無競態條件

- [ ] T048 [P] 實現系統恢復協調器
  - 位置：[firmware/src/safety/recovery_manager.c](../../../firmware/src/safety/recovery_manager.c)
  - 驗收標準：
    - recovery_request() 啟動恢復流程
    - 故障清除驗證
    - 恢復超時保護 (100ms)
    - 狀態轉遷正確

### 6.2 故障聚合硬體驗證

- [ ] T049 [P] 實現故障聚合和優先級 UVM 測試
  - 位置：[verification/testbench/safety_manager_tb.sv](../../../verification/testbench/safety_manager_tb.sv)
  - 驗收標準：
    - 15 個多故障場景
    - 優先級排序驗證
    - SC ≥ 100%, BC ≥ 99%

- [ ] T050 [P] 實現故障聚合故障注入測試
  - 位置：[verification/tests/aggregation_fault_injection_test.sv](../../../verification/tests/aggregation_fault_injection_test.sv)
  - 驗收標準：
    - 聚合邏輯故障模型
    - DC > 95%

### 6.3 故障聚合軟體驗證

- [ ] T051 [P] 優化故障聚合單元測試
  - 位置：[firmware/tests/unit/test_fault_aggregator.py](../../../firmware/tests/unit/test_fault_aggregator.py) [更新]
  - 驗收標準：
    - 25 個測試 (所有組合)
    - 優先級驗證
    - SC ≥ 100%, BC ≥ 100%

- [ ] T052 實現系統恢復整合測試
  - 位置：[firmware/tests/integration/test_recovery_flow.py](../../../firmware/tests/integration/test_recovery_flow.py)
  - 驗收標準：
    - 10 個恢復場景
    - 超時保護驗證
    - 多故障恢復序列

### 6.4 故障聚合文檔

- [ ] T053 [P] 編寫故障狀態機完整設計文檔
  - 位置：[docs/architecture/safety_fsm_design.md](../../../docs/architecture/safety_fsm_design.md)
  - 驗收標準：
    - 5 個狀態完整描述
    - 轉遷規則詳解
    - 優先級定義

- [ ] T054 [P] 創建故障聚合的追蹤矩陣
  - 位置：[docs/analysis/traceability_us4.md](../../../docs/analysis/traceability_us4.md)
  - 驗收標準：
    - SG (all) → FSR-004 → SysReq-002 → TSR-003
    - 100% 映射

- [ ] T055 實現完整系統追蹤矩陣 (綜合 US1-US4)
  - 位置：[docs/analysis/complete_traceability_matrix.md](../../../docs/analysis/complete_traceability_matrix.md)
  - 驗收標準：
    - 所有 SG/FSR/SysReq/TSR 的雙向追蹤
    - 無孤立需求
    - 100% 覆蓋

---

## Phase 7: 拋光與跨領域考慮

**目標**: 完成代碼質量檢查、文檔、CI/CD 集成、最終驗證  
**獨立驗收**: MISRA C 通過, 覆蓋率達目標, 文檔完整  
**預計時間**: 2 天

### 7.1 代碼品質和 MISRA C 合規

- [ ] T056 [P] 運行靜態分析工具 (cppcheck, Lizard, Clang) 並修復違規
  - 位置：[firmware/](../../../firmware/) [全代碼]
  - 驗收標準：
    - cppcheck: 0 高危缺陷
    - Lizard: CC ≤ 15 每個函數
    - Clang: 100% 類型檢查通過
    - MISRA C:2012: 0 關鍵違規, <10 警告

- [ ] T057 [P] 優化代碼以達到 MISRA C 合規性
  - 位置：[firmware/src/](../../../firmware/src/) [相關文件]
  - 驗收標準：
    - 移除所有動態分配
    - 使用 volatile 聲明故障標誌
    - 避免浮點運算
    - 限制指針使用

### 7.2 覆蓋率集成和報告

- [ ] T058 [P] 集成 gcov/lcov 生成 HTML 覆蓋率報告
  - 位置：[firmware/coverage/](../../../firmware/coverage/)
  - 驗收標準：
    - gcov 配置完成
    - lcov 報告 HTML 生成
    - 門控檢查：SC ≥ 98%, BC ≥ 98%, DC ≥ 90%

- [ ] T059 [P] 生成 RTL 覆蓋率報告 (Verilator + SystemVerilog coverage)
  - 位置：[verification/coverage/rtl_coverage_report/](../../../verification/coverage/rtl_coverage_report/)
  - 驗收標準：
    - 語句覆蓋 ≥ 99%
    - 分支覆蓋 ≥ 98%
    - FSM 狀態覆蓋 = 100%

### 7.3 持續集成配置

- [ ] T060 [P] 配置 GitHub Actions/GitLab CI 流程
  - 位置：[.github/workflows/ci.yml](../../../.github/workflows/ci.yml)
  - 驗收標準：
    - 編譯檢查 (gcc + verilator)
    - 單元測試 (pytest)
    - 靜態分析 (cppcheck, Lizard)
    - 覆蓋率門控 (SC/BC/DC)

- [ ] T061 [P] 實現預提交檢查 (pre-commit hooks)
  - 位置：[.pre-commit-config.yaml](../../../.pre-commit-config.yaml)
  - 驗收標準：
    - 代碼格式檢查 (astyle/clang-format)
    - 靜態檢查 (前提交)
    - 提交消息驗證

### 7.4 最終文檔和驗收

- [ ] T062 [P] 編寫完整系統架構文檔
  - 位置：[docs/architecture/complete_system_architecture.md](../../../docs/architecture/complete_system_architecture.md)
  - 驗收標準：
    - 3 層架構 (HW/Interface/SW) 詳解
    - 時序圖和控制流程
    - 性能指標總結

- [ ] T063 編寫 ASIL-B 符合性報告 (更新)
  - 位置：[specs/001-power-management-safety/asil-b-compliance-report.md](../../../specs/001-power-management-safety/asil-b-compliance-report.md)
  - 驗收標準：
    - 追蹤矩陣 100% 完整
    - 覆蓋率達成驗證
    - 風險評估完成
    - 符合性聲明

---

## 任務依賴圖

```
T001 (Init Branch)
  ↓
T002-T004 (Directory Setup) [並行]
  ↓
T005-T006 (Tool Setup) [並行]
  ↓
T007-T014 (Foundational) [US1-US4 共用前置條件]
  ├─ T015-T025 (US1: Power) [並行 with US2]
  ├─ T026-T035 (US2: Clock) [並行 with US1]
  ├─ T036-T046 (US3: Memory) [依賴 US1/US2 完成]
  └─ T047-T055 (US4: Fault Mgmt) [依賴 US1-US3 完成]
  ↓
T056-T063 (Polish & Validation) [所有故事完成後]
```

---

## 並行執行策略

### 批次 1 (Day 1-2): 基礎設施
```
T001 (串行: 初始化)
T002-T006 (並行: 目錄和工具)
```

### 批次 2 (Day 2-3): 共用組件
```
T007-T014 (並行: HAL, FSM, 故障聚合)
```

### 批次 3 (Day 4-7): US1 + US2 並行
```
T015-T025 (US1: Power - 4 人)
T026-T035 (US2: Clock - 4 人)
```

### 批次 4 (Day 7-9): US3 + US4 並行
```
T036-T046 (US3: Memory - 4 人) [依賴 T015-T025]
T047-T055 (US4: Fault Mgmt - 3 人) [依賴 T026-T035]
```

### 批次 5 (Day 9-11): 拋光
```
T056-T063 (並行: 代碼質量, CI/CD, 文檔)
```

---

## 檢查點和驗收準則

### 檢查點 1: Phase 1+2 完成 (T001-T014)
✓ 代碼庫就緒  
✓ 工具鏈可運行  
✓ 基礎組件可編譯  

### 檢查點 2: US1 完成 (T015-T025)
✓ VDD 監控 RTL 驗證通過 (SC ≥ 99%)  
✓ 軟體單元/整合測試通過  
✓ 可進入下一故事  

### 檢查點 3: US2 完成 (T026-T035)
✓ 時鐘監控 RTL 驗證通過 (SC ≥ 100%)  
✓ 軟體單元/整合測試通過  
✓ 可進入 US3/US4  

### 檢查點 4: US3+US4 完成 (T036-T055)
✓ ECC 和故障聚合驗證通過  
✓ DC > 90% 達成  
✓ 全系統集成測試通過  

### 檢查點 5: Phase 7 完成 (T056-T063)
✓ MISRA C 合規  
✓ 覆蓋率達目標 (SC=100%, BC=100%, DC>90%)  
✓ 文檔完整  
✓ 交付準備完成  

---

## 資源分配建議

| 角色 | 任務 | 人數 | 天數 |
|------|------|------|------|
| RTL 設計師 | T002, T015-T017, T026-T027, T036-T038 | 1 | 3-4 |
| 軟體工程師 | T003, T018-T019, T028-T029, T039-T040 | 1 | 2-3 |
| 驗證工程師 | T004, T020-T021, T030-T031, T041-T042 | 1 | 3-4 |
| 測試工程師 | T006, T022-T023, T032-T033, T043-T044 | 1 | 2-3 |
| 技術文檔師 | T005, T024-T025, T034-T035, T062-T063 | 1 | 2 |
| **總計** | **T001-T063** | **5** | **18** |

---

## 風險與緩解

| 風險 | 影響 | 概率 | 緩解 |
|------|------|------|------|
| RTL 時序不達 | 延遲超 1μs | 低 | 提前 FPGA 原型驗證 |
| 測試覆蓋不足 | DC < 90% | 中 | 加強故障注入測試 |
| 類比精度漂移 | 邊界不清晰 | 中 | 使用帶隙基準參考 |
| 工具鏈問題 | 驗證卡殼 | 低 | 保持備用商用工具 |
| MISRA C 違規過多 | 交付延遲 | 中 | 從 Phase 2 開始強制執行 |

---

## 成功指標

✅ **功能完整性**:
- VDD 檢測 < 1μs
- 時鐘檢測 < 100ns
- 軟體反應 < 5ms
- ECC SBE 糾正 > 99%, MBE 檢測 100%

✅ **品質指標**:
- SC = 100% (所有語句執行)
- BC = 100% (所有分支執行)
- DC > 90% (故障檢測能力)
- MISRA C: 0 關鍵違規

✅ **文檔完整性**:
- 追蹤矩陣 100% 覆蓋
- 所有設計文檔完成
- ASIL-B 符合性驗證

✅ **交付準備**:
- 所有代碼 review 完成
- CI/CD 自動化驗證
- 獨立評審通過

---

## 附錄：文件結構快速參考

```
specs/001-power-management-safety/
├── plan.md                          # 實現計畫 ✅
├── spec.md                          # 功能規格 ✅
├── research.md                      # Phase 0 研究 ✅
├── tasks.md                         # 本文件 (實現任務)
├── aspice-cl3-compliance.md         # CL3 符合性 ✅
├── traceability-analysis.md         # 追蹤分析 ✅
└── checklists/
    └── specification-quality.md     # 規格品質清單 ✅

rtl/                                 # 硬體 RTL
├── power_monitor/
├── clock_monitor/
├── memory_protection/
└── top_level/

firmware/                            # 固件代碼
├── src/                             # 源代碼
│   ├── power/
│   ├── clock/
│   ├── memory/
│   ├── safety/
│   └── hal/
├── include/                         # 頭文件
├── tests/                           # pytest 測試
│   ├── unit/
│   ├── integration/
│   └── coverage/
└── requirements.txt                 # Python 依賴

verification/                        # UVM 驗證
├── testbench/
├── agents/
├── tests/
└── coverage/

docs/                                # 文檔
├── architecture/
├── analysis/
└── procedures/
```

---

**生成日期**: 2025-12-03  
**版本**: 1.0.0  
**狀態**: READY FOR EXECUTION  
**下一步**: 執行 Phase 1 Setup (T001-T006)

**End of Implementation Tasks Document**
