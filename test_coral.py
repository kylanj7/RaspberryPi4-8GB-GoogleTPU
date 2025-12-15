#!/usr/bin/env python3
import sys
print(f"Python: {sys.version}\n")

results = {}

# Test TFLite
try:
    import tflite_runtime.interpreter as tflite
    results['tflite-runtime'] = '✓'
except Exception as e:
    results['tflite-runtime'] = f'✗ {str(e)[:50]}'

# Test PyCoral
try:
    from pycoral.utils import edgetpu
    from pycoral.adapters import common, classify
    results['pycoral'] = '✓'
except Exception as e:
    results['pycoral'] = f'✗ {str(e)[:50]}'

# Test libedgetpu
try:
    import ctypes
    ctypes.CDLL('libedgetpu.so.1')
    results['libedgetpu'] = '✓'
except Exception as e:
    results['libedgetpu'] = f'✗ {str(e)[:50]}'

# Test TPU detection
try:
    from pycoral.utils import edgetpu
    devices = edgetpu.list_edge_tpus()
    results['TPU devices'] = f'✓ Found {len(devices)}'
except Exception as e:
    results['TPU devices'] = f'✗ {str(e)[:50]}'

# Other packages
for pkg in ['numpy', 'PIL', 'cv2']:
    try:
        __import__(pkg)
        results[pkg] = '✓'
    except:
        results[pkg] = '✗'

print("="*50)
for k, v in results.items():
    print(f"{k:20s}: {v}")
print("="*50)

all_ok = all('✓' in str(v) for v in results.values())
print("\n🎉 READY FOR COMPUTER VISION!" if all_ok else "\n⚠️ Issues found")
