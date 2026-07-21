from pathlib import Path
import sys
import fitz

root = Path(__file__).resolve().parents[1]
source = Path(sys.argv[1]) if len(sys.argv) > 1 else root / "output" / "pdf" / "sample-payslip.pdf"
target = root / "tmp" / "pdfs" / f"{source.stem}.png"
target.parent.mkdir(parents=True, exist_ok=True)
document = fitz.open(source)
page = document[0]
page.get_pixmap(matrix=fitz.Matrix(1.5, 1.5), alpha=False).save(target)
print(f"pages={document.page_count} width={page.rect.width} height={page.rect.height} output={target}")
