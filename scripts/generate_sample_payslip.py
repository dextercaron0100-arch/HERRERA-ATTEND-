from pathlib import Path
from reportlab.lib import colors
from reportlab.lib.pagesizes import A4
from reportlab.pdfgen import canvas

output = Path(__file__).resolve().parents[1] / "output" / "pdf" / "sample-payslip.pdf"
output.parent.mkdir(parents=True, exist_ok=True)
c = canvas.Canvas(str(output), pagesize=A4)
width, height = A4
green = colors.HexColor("#163c2b")
c.setFillColor(green); c.setFont("Helvetica-Bold", 22); c.drawString(54, height - 64, "Herrera Demo Company")
c.setFillColor(colors.HexColor("#18201b")); c.setFont("Helvetica-Bold", 16); c.drawRightString(width - 54, height - 64, "PAYSLIP")
c.setFillColor(colors.HexColor("#66736b")); c.setFont("Helvetica", 10)
c.drawString(54, height - 105, "Employee: Maria Santos (EMP-001)")
c.drawString(54, height - 121, "Pay period: 16-31 July 2026")
c.drawString(54, height - 137, "Policy: Demo pilot policy v1 | Currency: PHP")
y = height - 184
rows = [("Basic pay", "10,000.00"), ("Approved overtime", "250.00"), ("Demo meal allowance", "500.00"), ("Late and undertime", "(50.00)"), ("Approved demo contribution", "(100.00)")]
c.setFillColor(colors.HexColor("#18201b")); c.setFont("Helvetica-Bold", 9); c.drawString(54, y, "LINE ITEM"); c.drawRightString(width - 54, y, "AMOUNT")
y -= 18; c.setStrokeColor(colors.HexColor("#d9e1dc")); c.line(54, y + 9, width - 54, y + 9); c.setFont("Helvetica", 10)
for label, amount in rows:
    c.drawString(54, y, label); c.drawRightString(width - 54, y, f"PHP {amount}"); y -= 24
c.line(54, y + 10, width - 54, y + 10); y -= 14
c.drawRightString(width - 54, y, "Gross pay: PHP 10,750.00"); y -= 18
c.drawRightString(width - 54, y, "Deductions: PHP 150.00"); y -= 27
c.setFillColor(green); c.setFont("Helvetica-Bold", 15); c.drawRightString(width - 54, y, "NET PAY: PHP 10,600.00")
c.setFillColor(colors.HexColor("#66736b")); c.setFont("Helvetica", 8); c.drawCentredString(width / 2, 55, "Generated from payroll snapshot revision 1. Demo data - not a statutory payroll result.")
c.save()
print(output)
