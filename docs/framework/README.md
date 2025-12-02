# ISO 26262 + ASPICE 特性規格框架

**標準符合**：ISO 26262-1:2018 + ASPICE 能力等級 3  
**汽車焦點**：SSD 控制器 (硬體 + 韌體)  
**版本**：1.0.0  
**最後更新**：2025-12-02

---

## 此框架提供的內容

完整的、生產就緒的系統，用於開發具有以下特性的安全關鍵特性：

✅ **階層式需求可追蹤性**
- 安全目標 → 功能安全需求 → 系統需求 → 技術安全需求
- 雙向可追蹤性 (自上而下和自下而上)
- 自動化差距檢測

✅ **整合安全性分析 (ISO 26262-9)**
- FMEA (失效模式與影響分析)
- FTA (故障樹分析)
- DFA (相關失效分析)

✅ **結構化特性開發流程**
- 7 階段生命週期，含品質關卡
- 階段關卡批准標準
- 審查和簽署工作流程

✅ **自動化可追蹤性驗證**
- PowerShell 指令碼進行可追蹤性檢查
- 變更影響分析
- 覆蓋率差距識別

✅ **完整的文檔範本**
- 需求規格範本
- 設計規格範本
- 測試規格範本
- 安全分析範本
- 可追蹤性矩陣範本

✅ **詳細的實施指南**
- 特性建立指南
- 流程指南
- 最佳實踐和經驗教訓

---

## 目錄結構

```
docs/framework/
├── README.md                         (此文件)
├── FRAMEWORK.md                      (主框架文檔)
├── IMPLEMENTATION-SUMMARY.md         (實施摘要)
│
├── templates/                        (所有規格範本)
│   ├── REQUIREMENTS-TEMPLATE.md      (需求規格)
│   ├── SAFETY-ANALYSIS-TEMPLATE.md   (安全分析)
│   └── TRACEABILITY-MATRIX-TEMPLATE.md (可追蹤性)
│
└── guides/                           (詳細指南)
    ├── FEATURE-CREATION-GUIDE.md    (如何建立特性)
    └── PROCESS-GUIDE.md             (流程細節)

specs/                                 (特性目錄，自動建立)
├── 001-power-loss-protection/       (特性 001 範例)
│   ├── spec.md
│   ├── requirements.md
│   ├── architecture.md
│   ├── detailed-design.md
│   ├── fmea.md
│   ├── fta.md
│   ├── unit-test-spec.md
│   ├── integration-test-spec.md
│   ├── system-test-spec.md
│   ├── traceability.md
│   └── review-records/
│
├── 002-thermal-management/
├── 003-error-correction/
└── ...

.specify/scripts/                     (自動化指令碼)
├── create-feature.ps1               (建立新特性)
└── check-traceability.ps1           (驗證可追蹤性)
```

---

## 快速開始 (5 分鐘)

### 1. 建立新特性

```powershell
PS> cd .specify/scripts
PS> .\create-feature.ps1 -Name "我的特性名稱" -ASIL "B" -Type "System"
```

**輸出**：
```
✓ 特性已建立：001-my-feature-name
✓ 目錄結構已建立
✓ 所有 13 個範本已填充
✓ 特性 ID：001
✓ 特性所有者已分配
```

### 2. 遵循 7 階段流程

| 階段 | 時間 | 主要活動 |
|------|------|--------|
| 1：初始化 | 1-2 天 | 定義範圍、確定 ASIL |
| 2：需求 | 3-5 天 | 建立 SG/FSR/SYS-REQ/TSR |
| 3：設計 | 4-7 天 | 架構和詳細設計 |
| 4：安全 | 3-5 天 | FMEA/FTA/DFA |
| 5：實施 | 8-14 天 | 代碼和測試 |
| 6：審查 | 2-3 天 | 所有批准 |
| 7：發佈 | 1 天 | Git 標籤和存檔 |

### 3. 驗證可追蹤性

```powershell
PS> .\check-traceability.ps1 -Feature "001-my-feature-name" -Report
```

**輸出**：
```
正向涵蓋率：100% (所有需求都有設計/代碼/測試)
反向涵蓋率：100% (所有代碼都可追蹤到需求)
孤立項目：0 個
狀態：✓ 完整且經過驗證
```

### 4. 在 Git 中提交

```powershell
PS> git add specs/001-my-feature-name/
PS> git commit -m "feat: implement feature 001 - my feature name

- SG: Safety Goal defined
- FSR: Functional Safety Requirement derived
- SYS-REQ: System Requirements developed
- TSR: Technical Safety Requirements allocated
- 100% traceability coverage verified
- All phase gates passed"
PS> git tag -a "001-my-feature-name-v1.0" -m "Feature 001 release"
```

---

## 詳細指南

### 了解基礎知識 (30 分鐘)

1. **閱讀**：[FRAMEWORK.md](FRAMEWORK.md) - 框架概念和方法論
2. **掃描**：[IMPLEMENTATION-SUMMARY.md](IMPLEMENTATION-SUMMARY.md) - 已交付內容概述

### 建立您的第一個特性 (2-3 小時)

1. **遵循**：[FEATURE-CREATION-GUIDE.md](guides/FEATURE-CREATION-GUIDE.md)
   - 第 1 階段：初始化 (30 分鐘)
   - 第 2 階段：需求 (1 小時)
   - 第 3 階段：設計 (30 分鐘)
   - 第 4 階段：安全 (30 分鐘)

### 理解流程細節 (1 小時)

1. **研究**：[PROCESS-GUIDE.md](guides/PROCESS-GUIDE.md)
   - 品質關卡
   - 審查標準
   - 批准工作流程

### 使用範本

1. **需求**：[templates/REQUIREMENTS-TEMPLATE.md](templates/REQUIREMENTS-TEMPLATE.md)
   - 如何編寫 SG/FSR/SYS-REQ/TSR
   - 可追蹤性連結
   - ASIL 繼承

2. **安全分析**：[templates/SAFETY-ANALYSIS-TEMPLATE.md](templates/SAFETY-ANALYSIS-TEMPLATE.md)
   - FMEA 範例
   - FTA 結構
   - DFA 方法

3. **可追蹤性**：[templates/TRACEABILITY-MATRIX-TEMPLATE.md](templates/TRACEABILITY-MATRIX-TEMPLATE.md)
   - 正向矩陣
   - 反向矩陣
   - 覆蓋率指標

---

## 標準對應

### ISO 26262-1:2018 覆蓋

| 部分 | 主題 | 框架支援 |
|------|------|--------|
| 1 | 概念 | 階層式需求、ASIL 等級、功能安全 |
| 2 | 要求 | 框架標準、流程要求 |
| 3 | 概念與方法論 | 功能安全論證、FMEA/FTA/DFA |
| 4 | 軟體設計 | 軟體架構和詳細設計範本 |
| 5 | 硬體設計 | 硬體架構和設計範本 |
| 6 | 產品整合 | 系統測試範本 |
| 8 | 規格和管理 | 需求框架和可追蹤性 |
| 9 | 功能安全評估 | FMEA/FTA/DFA 範本 |

### ASPICE CL3 對應

| 流程 | 能力等級 | 框架支援 |
|------|--------|--------|
| SYS.1-5 | CL3 | 系統需求到資格認證測試 |
| SWE.1-6 | CL3 | 軟體需求到驗收測試 |
| HWE.1-5 | CL3 | 硬體設計到集成測試 |
| SUP.2,8,9,10 | CL3 | 驗證、配置管理、問題解決 |

---

## 自動化指令碼

### create-feature.ps1

**目的**：快速生成新特性目錄和範本

**用法**：
```powershell
.\create-feature.ps1 `
  -Name "特性名稱" `
  -ASIL "B" `
  -Type "System|Hardware|Firmware" `
  -Owner "所有者名稱" `
  -Stakeholders "利害關係人 1, 利害關係人 2" `
  -Description "特性簡短描述"
```

**輸出**：
- 特性目錄：`specs/NNN-feature-name/`
- 13 個預填充的範本
- 自動分配的特性 ID (001, 002, 003...)
- 可追蹤性矩陣初始化

### check-traceability.ps1

**目的**：驗證雙向可追蹤性完整性

**用法**：
```powershell
.\check-traceability.ps1 `
  -Feature "001-feature-name" `
  -Report
```

**輸出**：
- 正向涵蓋率 (% 需求有設計/代碼/測試)
- 反向涵蓋率 (% 代碼可追蹤到需求)
- 孤立項目清單
- 未追蹤項目清單
- 總體合規性狀態

### 計畫中的指令碼

- `check-change-impact.ps1` - 分析需求/設計/代碼變更的影響
- `check-requirements-coverage.ps1` - 生成覆蓋率報告
- `check-verification-status.ps1` - 驗證指標儀表板

---

## 最佳實踐

### 應該做

✅ **從需求開始**  
未經需求審查和可追蹤性，請勿進行設計或實施。

✅ **及早涉及安全**  
安全經理應從第 1 階段起參與，不是事後想法。

✅ **自動化驗證**  
使用指令碼檢查可追蹤性、覆蓋率和變更影響。

✅ **記錄決策**  
捕捉"為什麼"決定了每個需求或設計選擇。

✅ **在實施前編寫測試**  
測試驅動開發有助於確保代碼符合需求。

✅ **持續審查**  
不要等到階段末期進行審查；邊做邊檢查。

✅ **維護基線**  
在每個階段關卡建立可重現的代碼基線。

### 不應該做

❌ **不要跳過需求審查**  
所有審查都是強制性的；無法跳過。

❌ **不要沒有可追蹤性標籤就提交代碼**  
所有代碼行都必須有 `@requirement` 標籤。

❌ **不要放棄涵蓋率目標**  
ASIL-B 需要 100% 的語句和分支涵蓋率。

❌ **不要跳過安全性分析**  
FMEA/FTA/DFA 對於識別和減輕風險至關重要。

❌ **不要在未進行影響分析的情況下變更需求**  
所有變更都必須進行影響分析。

❌ **不要合併失敗的驗證**  
所有測試必須通過；不接受零失敗。

❌ **不要在未進行最終審查的情況下發佈**  
所有批准都必須簽署才能發佈。

---

## 常見問題

**Q：此框架是否強制性的？**  
A：是的。ISO 26262 和 ASPICE CL3 要求都是強制性的；所有特性必須遵循此流程。

**Q：我可以並行化階段嗎？**  
A：否。後期階段相依於早期階段的輸出。例如，您無法在完成需求之前設計。

**Q：測試真的需要 100% 涵蓋率嗎？**  
A：是的，針對 ASIL-B 及以上。任何無法測試的代碼必須進行正當理由說明。

**Q：我是否需要所有三種安全分析 (FMEA/FTA/DFA)？**  
A：是的。ISO 26262-9 要求它們都進行。簡化會導致風險。

**Q：可追蹤性可以自動化嗎？**  
A：部分可以。`check-traceability.ps1` 檢查標籤和矩陣。人工審查仍然是必要的。

**Q：誰簽署審查？**  
A：技術主管(架構)、安全經理(安全分析)和測試主管(驗證)簽署相關審查。

**Q：基線應該有多頻繁？**  
A：在每個階段關卡之後。至少每週一次，或在重大變更後立即進行。

**Q：我可以重用其他特性的需求嗎？**  
A：是的，但每個實例必須追蹤回源特性。相同需求不應重複。

---

## 支援和聯絡

- **流程問題**：聯絡流程所有者
- **技術問題**：聯絡技術主管
- **安全問題**：聯絡安全經理
- **工具問題**：參閱 `.specify/scripts/` 中的指令碼註解

---

## 版本歷史

| 版本 | 日期 | 變更 |
|------|------|------|
| 1.0.0 | 2025-12-02 | 初始發佈 |

---

## 相關文檔

- [FRAMEWORK.md](FRAMEWORK.md) - 完整框架參考
- [IMPLEMENTATION-SUMMARY.md](IMPLEMENTATION-SUMMARY.md) - 交付摘要
- [FEATURE-CREATION-GUIDE.md](guides/FEATURE-CREATION-GUIDE.md) - 特性建立逐步介紹
- [PROCESS-GUIDE.md](guides/PROCESS-GUIDE.md) - 流程細節和標準

---

**準備開始？** 執行 `.\create-feature.ps1` 建立您的第一個特性！

---

**文檔版本**：1.0.0  
**最後更新**：2025-12-02  
**下次審查**：2026-03-02
