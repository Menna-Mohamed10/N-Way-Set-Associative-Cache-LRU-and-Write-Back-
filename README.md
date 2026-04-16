# N-Way Set Associative Cache with LRU & Write-Back (Verilog)

## 📌 Overview
This project implements an **N-way set-associative cache system** in **Verilog** using:
- **LRU (Least Recently Used)** replacement policy
- **Write-Back** write policy
- **FSM-based Cache Controller**
- **64K × 32-bit synchronous RAM**

The default cache configuration is **4-way set associative** with **64 sets**.

---

## 📷 Design
Add the system design image / waveform screenshots here.

---

## 📁 Files
```text
Cache.v
Cache_Controller.v
Cache_Controller_Testbench.v
RAM.v
Wrapper.v
README.md
```

---

## Modules

### 🔹 Cache Module
- Stores **valid bit, dirty bit, tag, and data**
- Supports read/write operations
- Default: **4 ways, 64 sets**

### 🔹 Cache Controller
Implemented using a **Finite State Machine (FSM)** with states for:
- Cache hit / miss detection
- Read and write handling
- LRU replacement
- Write-back to RAM
- Cache update

### 🔹 RAM Module
- **64K × 32-bit synchronous RAM**
- Parameterized bit width
- Supports read/write operations

### 🔹 Wrapper Module
Integrates:
- Cache
- Cache Controller
- RAM

---

## 🔁 Cache Policies

### Replacement Policy — LRU
The controller keeps track of usage priority for each way in every set using:
```verilog
lru[SETS_NUMBER][WAY_NUM]
```

On a cache miss, the **least recently used way** is selected for replacement.

### Write Policy — Write-Back
- On write hit → update cache only and set **dirty = 1**
- On replacement → dirty lines are written back to RAM first

This reduces unnecessary memory writes and improves performance.

---

## 🧪 Testbench
The testbench verifies:

### Test 1
- Initial cache miss
- Load from RAM
- Next access becomes a hit

### Test 2
- Fill all ways in one set
- Verify stored values

### Test 3
- Trigger LRU replacement
- Modify data
- Verify write-back to RAM

Simulation and waveforms were verified using **QuestaSim**.

---



