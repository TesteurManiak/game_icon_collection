import sys
from pyctr.type.smdh import SMDH


def main() -> int:
    if len(sys.argv) != 3:
        print("Usage: python _icon_to_png.py <icon.bin> <output.png>")
        return 1

    input_bin = sys.argv[1]
    output_png = sys.argv[2]

    try:
        icon = SMDH.from_file(input_bin)
        icon.icon_large.save(output_png)
        return 0
    except Exception as exc:
        print(f"Conversion error: {exc}")
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
