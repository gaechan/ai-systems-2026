---
title: 인프라 가이드
description: DGX H100, MIG, Kubernetes 운영 가이드 — 제주한라대학교 AI 실습 환경
---

## AI 실습실 인프라

### DGX H100 사양

| 항목 | 사양 |
|------|------|
| GPU | NVIDIA H100 SXM5 × 8 |
| GPU 메모리 | 80GB HBM3 × 8 (총 640GB) |
| CPU | Intel Xeon Platinum 8480C × 2 (112코어) |
| 시스템 메모리 | 2TB DDR5 |
| 스토리지 | 7.68TB NVMe SSD |
| 네트워크 | 8 × InfiniBand 400Gb/s |

### MIG 슬라이스 할당

각 학생에게 `1g.10gb` MIG 슬라이스 1개가 할당된다:

| 슬라이스 타입 | GPU 메모리 | 최대 인스턴스 | 적합한 용도 |
|-------------|-----------|------------|-----------|
| `1g.10gb` | 10GB | 7개 | vLLM Lite 모델, 실습 |
| `2g.20gb` | 20GB | 3개 | 중간 규모 모델 |
| `3g.40gb` | 40GB | 2개 | 대규모 배포 |
| `7g.80gb` | 80GB | 1개 | 전체 GPU |

### 서버 접속

```bash
# SSH 접속
ssh [학번]@dgx.chu.ac.kr

# 할당된 MIG 확인
nvidia-smi mig -lgip

# GPU 사용률 모니터링
nvidia-smi dmon -s u -d 5  # 5초 간격

# 할당된 MIG 슬라이스에서 Python 실행
CUDA_VISIBLE_DEVICES=MIG-GPU-[UUID] python your_script.py
```

### Kubernetes 워크로드 실행

```yaml
# job.yaml — 배치 작업 제출
apiVersion: batch/v1
kind: Job
metadata:
  name: [학번]-experiment
  namespace: ai-systems
spec:
  template:
    spec:
      containers:
      - name: experiment
        image: pytorch/pytorch:2.5-cuda12-cudnn9-devel
        command: ["python", "train.py"]
        resources:
          limits:
            nvidia.com/mig-1g.10gb: "1"
            memory: "16Gi"
            cpu: "8"
        volumeMounts:
        - name: workspace
          mountPath: /workspace
      volumes:
      - name: workspace
        persistentVolumeClaim:
          claimName: [학번]-pvc
      restartPolicy: Never
```

```bash
# Job 제출
kubectl apply -f job.yaml -n ai-systems

# 로그 확인
kubectl logs -f job/[학번]-experiment -n ai-systems

# Job 삭제
kubectl delete job [학번]-experiment -n ai-systems
```

### 스토리지

| 경로 | 용량 | 용도 |
|------|------|------|
| `/home/[학번]` | 100GB | 홈 디렉토리 |
| `/workspace/[학번]` | 500GB | 실습 프로젝트 |
| `/data/shared` | 10TB | 공용 데이터셋 (읽기 전용) |
| `/models/cache` | 5TB | 공용 모델 캐시 (읽기 전용) |

### 유용한 명령어

```bash
# 디스크 사용량 확인
du -sh /workspace/[학번]/*

# 프로세스 확인
ps aux | grep python

# GPU 프로세스 확인
nvidia-smi

# Slurm 작업 목록 (대기 중인 작업)
squeue -u [학번]
```

### 주의사항

1. **컴퓨팅 자원 절약**: 실습이 끝나면 프로세스를 종료하세요
2. **대용량 파일**: 1GB 이상 파일은 `/data/shared`에 공유 요청
3. **모델 다운로드**: `/models/cache`에 이미 있는 모델은 재다운로드 불필요
4. **야간 배치**: 장시간 실험은 야간(22:00–06:00)에 Kubernetes Job으로 제출

### 문의

기술적 문제는 AI 실습실 관리자 (lab@chu.ac.kr) 또는 [GitHub Issue](https://github.com/halla-ai/ai-systems-2026/issues)
