#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Universal Mathematical Accuracy Verification Suite for Signed INT8 Multipliers.
Exhaustively evaluates all 65,536 input combinations [-128, 127] x [-128, 127].
Calculates MRED (%), Mean Error Distance (MED), and Worst-Case Error (WCE).
Supports:
  - baseline: Exact 8-bit multiplier (0% error)
  - v9_ultra: Fused Ultra Architecture (LOW_W=2, TRUNC=4, Zero-Adder) -> 58 LUTs
  - v9_nano : Fused Sub-50 Architecture (LOW_W=1, TRUNC=6, Zero-Adder) -> 45 LUTs
  - v8_legacy: V8 Baseline Architecture (LOW_W=3, TRUNC=4, Carry-adder) -> 73 LUTs
Author: Conquerors Team - NGUYEN VAN THUC (24161421)
"""

import sys
import json
import argparse
from pathlib import Path

def eval_multiplier(arch="v9_ultra"):
    lut_low3 = [1, 3, 4, 4, 6, 6, 7, 7]
    lut_low2 = [1, 1, 2, 2, 3, 3, 3, 3] # calibrated 8-entry 2-bit
    lut_low1 = [0, 0, 0, 1, 1, 1, 1, 1] # calibrated 8-entry 1-bit

    total_ae = 0
    total_re = 0.0
    count_nz = 0
    max_ae = 0
    incorrect = 0
    worst_case = None

    for a in range(-128, 128):
        for b in range(-128, 128):
            exact = a * b
            if arch == "baseline":
                approx = exact

            elif arch == "v9_ultra":
                # Hardware bit-accurate emulation of lutalm_mul_s8 with LOW_W=2, TRUNC_BITS=4, ZERO_ADDER=1
                mag_a = (-a) & 0xFF if a < 0 else (a & 0xFF)
                mag_b = (-b) & 0xFF if b < 0 else (b & 0xFF)
                sign_prod = 1 if (a < 0) ^ (b < 0) else 0
                zero_prod = 1 if (a == 0 or b == 0) else 0

                def enc_u8_low2(mag):
                    if mag == 0:
                        return 0
                    k = mag.bit_length() - 1
                    bits = ((mag << (7 - k)) & 0xFF) & 0x7F
                    high = (bits >> 4) & 7
                    addr = (bits >> 1) & 7
                    low = [1, 1, 2, 2, 3, 3, 3, 3][addr]
                    return (k << 5) | (high << 2) | low

                log_a = enc_u8_low2(mag_a)
                log_b = enc_u8_low2(mag_b)
                log_sum = log_a + log_b
                exp_w = (log_sum >> 5) & 0xF
                frac_w = log_sum & 0x1F
                mant_w = (1 << 5) | frac_w # 6 bits

                # Direct 12-bit antilog case
                if exp_w <= 3:
                    raw_trunc = 0
                elif exp_w == 4:
                    raw_trunc = (mant_w >> 5) & 1
                elif exp_w == 5:
                    raw_trunc = (mant_w >> 4) & 3
                elif exp_w == 6:
                    raw_trunc = (mant_w >> 3) & 7
                elif exp_w == 7:
                    raw_trunc = (mant_w >> 2) & 0xF
                elif exp_w == 8:
                    raw_trunc = (mant_w >> 1) & 0x1F
                elif exp_w == 9:
                    raw_trunc = mant_w & 0x3F
                elif exp_w == 10:
                    raw_trunc = (mant_w << 1) & 0x7F
                elif exp_w == 11:
                    raw_trunc = (mant_w << 2) & 0xFF
                elif exp_w == 12:
                    raw_trunc = (mant_w << 3) & 0x1FF
                elif exp_w == 13:
                    raw_trunc = (mant_w << 4) & 0x3FF
                elif exp_w == 14:
                    raw_trunc = (mant_w << 5) & 0x7FF
                else:
                    raw_trunc = (mant_w << 6) & 0xFFF

                if zero_prod:
                    signed_raw = 0
                else:
                    signed_raw = ((~raw_trunc) & 0xFFF) if sign_prod else raw_trunc

                res = (signed_raw << 4)
                if res >= 0x8000:
                    res -= 0x10000
                approx = res

            elif arch == "v9_ultra_compact":
                # Hardware bit-accurate emulation of lutalm_mul_s8 with MODE=1 (50-56 LUTs, MRED = 4.8299%)
                mag_a = ((~a) & 0x7F) | 1 if a < 0 else (a & 0x7F)
                mag_b = ((~b) & 0x7F) | 1 if b < 0 else (b & 0x7F)
                sign_prod = 1 if (a < 0) ^ (b < 0) else 0
                zero_prod = 1 if (a == 0 or b == 0) else 0

                def enc_ultra_50(mag):
                    if mag == 0: return 0, 0
                    for k in range(6, 0, -1):
                        if (mag >> k) & 1:
                            bits = ((mag << (7 - k)) & 0xFF) & 0x7F
                            high = (bits >> 4) & 7
                            b2 = (bits >> 3) & 1
                            b1 = (bits >> 2) & 1
                            low = (b2 | b1) << 1 | (b2 | (1 - b1))
                            frac = (high << 2) | low
                            return k, frac
                    return 0, 0

                ka, fa = enc_ultra_50(mag_a)
                kb, fb = enc_ultra_50(mag_b)
                log_sum = (ka << 5) + fa + (kb << 5) + fb
                exp_w = (log_sum >> 5) & 0xF
                frac_w = log_sum & 0x1F
                mant_w = (1 << 5) | frac_w

                if exp_w <= 3: raw_trunc = 0
                elif exp_w == 4: raw_trunc = (mant_w >> 5) & 1
                elif exp_w == 5: raw_trunc = (mant_w >> 4) & 3
                elif exp_w == 6: raw_trunc = (mant_w >> 3) & 7
                elif exp_w == 7: raw_trunc = (mant_w >> 2) & 0xF
                elif exp_w == 8: raw_trunc = (mant_w >> 1) & 0x1F
                elif exp_w == 9: raw_trunc = mant_w & 0x3F
                elif exp_w == 10: raw_trunc = (mant_w << 1) & 0x7F
                elif exp_w == 11: raw_trunc = (mant_w << 2) & 0xFF
                elif exp_w == 12: raw_trunc = (mant_w << 3) & 0x1FF
                elif exp_w == 13: raw_trunc = (mant_w << 4) & 0x3FF
                elif exp_w == 14: raw_trunc = (mant_w << 5) & 0x7FF
                else: raw_trunc = (mant_w << 6) & 0xFFF

                if zero_prod: signed_raw = 0
                else: signed_raw = ((~raw_trunc) & 0xFFF) if sign_prod else raw_trunc

                res = (signed_raw << 4)
                if res >= 0x8000: res -= 0x10000
                approx = res

            elif arch == "v9_nano":
                # Hardware bit-accurate emulation of lutalm_mul_s8 with LOW_W=1, TRUNC_BITS=6, ZERO_ADDER=1
                mag_a = (-a) & 0xFF if a < 0 else (a & 0xFF)
                mag_b = (-b) & 0xFF if b < 0 else (b & 0xFF)
                sign_prod = 1 if (a < 0) ^ (b < 0) else 0
                zero_prod = 1 if (a == 0 or b == 0) else 0
                eff_sign = 0 if zero_prod else sign_prod

                def enc_u8_low1(mag):
                    if mag == 0:
                        return 0
                    k = mag.bit_length() - 1
                    bits = ((mag << (7 - k)) & 0xFF) & 0x7F
                    high = (bits >> 4) & 7
                    addr = (bits >> 1) & 7
                    low = 0 if addr <= 2 else 1
                    return (k << 4) | (high << 1) | low

                log_a = enc_u8_low1(mag_a)
                log_b = enc_u8_low1(mag_b)
                log_sum = log_a + log_b
                raw_exp = (log_sum >> 4) & 0xF
                eff_exp = 0 if zero_prod else raw_exp
                frac_w = log_sum & 0xF
                mant_w = (1 << 4) | frac_w # 5 bits

                # Direct 10-bit antilog case
                if eff_exp <= 5:
                    raw_trunc = 0
                elif eff_exp == 6:
                    raw_trunc = (mant_w >> 4) & 1
                elif eff_exp == 7:
                    raw_trunc = (mant_w >> 3) & 3
                elif eff_exp == 8:
                    raw_trunc = (mant_w >> 2) & 7
                elif eff_exp == 9:
                    raw_trunc = (mant_w >> 1) & 0xF
                elif eff_exp == 10:
                    raw_trunc = mant_w & 0x1F
                elif eff_exp == 11:
                    raw_trunc = (mant_w << 1) & 0x3F
                elif eff_exp == 12:
                    raw_trunc = (mant_w << 2) & 0x7F
                elif eff_exp == 13:
                    raw_trunc = (mant_w << 3) & 0xFF
                elif eff_exp == 14:
                    raw_trunc = (mant_w << 4) & 0x1FF
                else:
                    raw_trunc = (mant_w << 5) & 0x3FF

                signed_raw = (raw_trunc ^ 0x3FF) if eff_sign else raw_trunc
                res = (signed_raw << 6)
                if res >= 0x8000:
                    res -= 0x10000
                approx = res

            elif arch == "v8_legacy":
                # Classic V8 (73 LUTs)
                def enc(x):
                    mag = (-x) & 0xFF if x < 0 else (x & 0xFF)
                    sign = 1 if x < 0 else 0
                    zero = (x == 0)
                    if zero or mag == 0:
                        return sign, zero, 0
                    k = mag.bit_length() - 1
                    bits = ((mag << (7 - k)) & 0xFF) & 0x7F
                    upper = (bits >> 4) & 7
                    addr = (bits >> 1) & 7
                    low = lut_low3[addr]
                    frac = (upper << 3) | low
                    return sign, zero, (k << 6) | frac

                sa, za, la = enc(a)
                sb, zb, lb = enc(b)
                log_sum = la + lb
                exp = (log_sum >> 6) & 0xF
                frac_s = log_sum & 0x3F
                mantissa = (1 << 6) | frac_s
                shifted = (mantissa << exp) >> 6
                approx_mag = shifted & 0xFFFF
                sign_prod = sa ^ sb
                zero_prod = za | zb
                trunc_bits = 4
                rem_bits = 16 - trunc_bits
                round_bit = ((approx_mag >> (trunc_bits - 1)) & 1)
                raw_trunc = (approx_mag >> trunc_bits) & ((1 << rem_bits) - 1)
                eff_sign = sign_prod and not zero_prod
                eff_round = round_bit and not zero_prod
                eff_raw = 0 if zero_prod else raw_trunc
                carry_in = (not eff_round) if eff_sign else eff_round
                base = (~eff_raw & ((1 << rem_bits) - 1)) if eff_sign else eff_raw
                signed_mag = (base + carry_in) & ((1 << rem_bits) - 1)
                res = signed_mag << trunc_bits
                if res >= 0x8000:
                    res -= 0x10000
                approx = res

            ae = abs(approx - exact)
            total_ae += ae
            if ae != 0:
                incorrect += 1
            if ae > max_ae:
                max_ae = ae
                worst_case = {"a": a, "b": b, "approx": approx, "exact": exact, "ae": ae}
            if exact != 0:
                total_re += ae / abs(exact)
                count_nz += 1

    mred = (total_re / count_nz * 100.0) if count_nz > 0 else 0.0
    med = total_ae / 65536.0
    error_rate = (incorrect / 65536.0) * 100.0

    return {
        "architecture": arch,
        "total_cases": 65536,
        "incorrect_cases": incorrect,
        "error_rate_pct": round(error_rate, 4),
        "MRED_pct": round(mred, 4),
        "MED": round(med, 4),
        "WCE": max_ae,
        "worst_case": worst_case
    }

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Evaluate Signed INT8 Multiplier Accuracy")
    parser.add_argument("--arch", choices=["baseline", "v9_ultra", "v9_ultra_compact", "v9_nano", "v8_legacy", "lutalm"], default="v9_ultra")
    parser.add_argument("--trunc", type=int, default=4, help="Ignored in V9")
    parser.add_argument("--quad", type=int, default=0, help="Ignored in V9")
    parser.add_argument("--out", type=str, default="")
    args = parser.parse_args()

    arch_mode = "v9_ultra" if args.arch == "lutalm" else args.arch
    res = eval_multiplier(arch=arch_mode)
    print(f"\n=======================================================")
    print(f" ACCURACY BENCHMARK RESULT: {args.arch.upper()}")
    print(f"=======================================================")
    print(f" MRED (%): {res['MRED_pct']:.4f}%")
    print(f" MED     : {res['MED']:.2f}")
    print(f" WCE     : {res['WCE']}")
    print(f" Error % : {res['error_rate_pct']:.2f}%")
    print(f"=======================================================\n")

    if args.out:
        out_path = Path(args.out)
        out_path.parent.mkdir(parents=True, exist_ok=True)
        out_path.write_text(json.dumps(res, indent=2))
        print(f"[OK] Saved results to: {out_path}")
