import { renderCsv,renderReportPdf } from './render';
const report={title:'Audit report',subtitle:'Demo',columns:[{key:'name',label:'Name'},{key:'amount',label:'Amount'}],rows:[{name:'Maria',amount:'100.00'},{name:'=unsafe',amount:'2'}]};
it('renders safe UTF-8 CSV',()=>{const csv=renderCsv(report);expect(csv.charCodeAt(0)).toBe(0xfeff);expect(csv).toContain("'=unsafe");});
it('renders a report PDF',async()=>{const pdf=await renderReportPdf(report);expect(pdf.subarray(0,4).toString()).toBe('%PDF');expect(pdf.length).toBeGreaterThan(1000);});
