# Cloudflare Placement Hints - Brazil Research

Generated: 2026-04-18 13:18:41 -03:00

## Methodology
- Test candidate reachability (L4 TCP and L7 HTTP HEAD).
- Build DNS profile (A/AAAA/CNAME count and CDN-like CNAME patterns).
- Detect CDN proxy hints in HTTP headers when L7 is tested.
- Score candidates and prefer likely single-homed endpoints.

## Summary
- Cities in matrix: 31
- Cities with recommendations: 30
- Recommendations without risk flags: 25

## Recommended Hints

| City | IATA | Hint Type | Hint Value | Score | Risk Flags |
|------|------|-----------|------------|-------|------------|
| Aracatuba | ARU | host | $(@{city=Aracatuba; iata=ARU; hintType=host; hintValue=unesp.br:443; expectedColo=ARU; source=UNESP - has Araçatuba campus; riskFlags=; score=135}.hintValue) | 135 | none |
| Belém | BEL | host | $(@{city=Belém; iata=BEL; hintType=host; hintValue=ufpa.br:443; expectedColo=BEL; source=Universidade Federal do Pará - Belém; riskFlags=; score=135}.hintValue) | 135 | none |
| Blumenau | BNU | host | $(@{city=Blumenau; iata=BNU; hintType=host; hintValue=furb.br:443; expectedColo=BNU; source=Universidade Regional de Blumenau; riskFlags=; score=135}.hintValue) | 135 | none |
| Brasília | BSB | host | $(@{city=Brasília; iata=BSB; hintType=host; hintValue=unb.br:443; expectedColo=BSB; source=Universidade de Brasília; riskFlags=; score=135}.hintValue) | 135 | none |
| Campos dos Goytacazes | CAW | host | $(@{city=Campos dos Goytacazes; iata=CAW; hintType=host; hintValue=uenf.br:443; expectedColo=CAW; source=UENF - state university in Campos; riskFlags=; score=135}.hintValue) | 135 | none |
| Caçador | CFC | host | $(@{city=Caçador; iata=CFC; hintType=host; hintValue=uniarp.edu.br:443; expectedColo=CFC; source=Universidade Alto Vale do Rio do Peixe - Caçador; riskFlags=; score=135}.hintValue) | 135 | none |
| Cuiabá | CGB | host | $(@{city=Cuiabá; iata=CGB; hintType=host; hintValue=ufmt.br:443; expectedColo=CGB; source=UFMT - federal university, Cuiabá; riskFlags=; score=135}.hintValue) | 135 | none |
| Belo Horizonte | CNF | host | $(@{city=Belo Horizonte; iata=CNF; hintType=host; hintValue=ufmg.br:443; expectedColo=CNF; source=UFMG - largest university in MG; riskFlags=; score=135}.hintValue) | 135 | none |
| Curitiba | CWB | host | $(@{city=Curitiba; iata=CWB; hintType=host; hintValue=ufpr.br:443; expectedColo=CWB; source=UFPR - major federal university, Curitiba; riskFlags=NOT_SINGLE_HOMED; score=115}.hintValue) | 115 | NOT_SINGLE_HOMED |
| Florianópolis | FLN | host | $(@{city=Florianópolis; iata=FLN; hintType=host; hintValue=ufsc.br:443; expectedColo=FLN; source=UFSC - federal university, Florianópolis; riskFlags=NOT_SINGLE_HOMED; score=115}.hintValue) | 115 | NOT_SINGLE_HOMED |
| Fortaleza | FOR | host | $(@{city=Fortaleza; iata=FOR; hintType=host; hintValue=ufc.br:443; expectedColo=FOR; source=UFC - federal university, Fortaleza; riskFlags=; score=135}.hintValue) | 135 | none |
| Rio de Janeiro | GIG | host | $(@{city=Rio de Janeiro; iata=GIG; hintType=host; hintValue=ufrj.br:443; expectedColo=GIG; source=UFRJ - major federal university, Rio de Janeiro; riskFlags=; score=135}.hintValue) | 135 | none |
| São Paulo | GRU | host | $(@{city=São Paulo; iata=GRU; hintType=host; hintValue=usp.br:443; expectedColo=GRU; source=USP - largest university in Brazil, São Paulo; riskFlags=; score=135}.hintValue) | 135 | none |
| Goiânia | GYN | host | $(@{city=Goiânia; iata=GYN; hintType=host; hintValue=ufg.br:443; expectedColo=GYN; source=UFG - federal university, Goiânia; riskFlags=NOT_SINGLE_HOMED; score=115}.hintValue) | 115 | NOT_SINGLE_HOMED |
| Juazeiro do Norte | JDO | host | $(@{city=Juazeiro do Norte; iata=JDO; hintType=host; hintValue=urca.br:443; expectedColo=JDO; source=URCA - state university, Juazeiro do Norte campus; riskFlags=; score=135}.hintValue) | 135 | none |
| Joinville | JOI | host | $(@{city=Joinville; iata=JOI; hintType=host; hintValue=univille.edu.br:443; expectedColo=JOI; source=UNIVILLE - private university in Joinville; riskFlags=; score=135}.hintValue) | 135 | none |
| Manaus | MAO | host | $(@{city=Manaus; iata=MAO; hintType=host; hintValue=ufam.edu.br:443; expectedColo=MAO; source=UFAM - federal university, Manaus; riskFlags=NOT_SINGLE_HOMED; score=115}.hintValue) | 115 | NOT_SINGLE_HOMED |
| Timbó | NVT | host | $(@{city=Timbó; iata=NVT; hintType=host; hintValue=univali.br:443; expectedColo=NVT; source=UNIVALI - covers Itajaí/Balneário Camboriú area near Timbó; riskFlags=; score=135}.hintValue) | 135 | none |
| Palmas | PMW | host | $(@{city=Palmas; iata=PMW; hintType=host; hintValue=uft.edu.br:443; expectedColo=PMW; source=UFT - federal university, Palmas (capital of Tocantins); riskFlags=; score=135}.hintValue) | 135 | none |
| Porto Alegre | POA | host | $(@{city=Porto Alegre; iata=POA; hintType=host; hintValue=tjrs.jus.br:443; expectedColo=POA; source=Tribunal de Justiça do RS; riskFlags=; score=135}.hintValue) | 135 | none |
| Americana | QWJ | host | $(@{city=Americana; iata=QWJ; hintType=host; hintValue=unisal.br:443; expectedColo=QWJ; source=Centro Universitário Salesiano - Americana campus; riskFlags=; score=135}.hintValue) | 135 | none |
| Ribeirão Preto | RAO | host | $(@{city=Ribeirão Preto; iata=RAO; hintType=host; hintValue=fmrp.usp.br:443; expectedColo=RAO; source=USP Ribeirão Preto - medical school campus; riskFlags=; score=135}.hintValue) | 135 | none |
| Recife | REC | host | $(@{city=Recife; iata=REC; hintType=host; hintValue=tjpe.jus.br:443; expectedColo=REC; source=Tribunal de Justiça de PE; riskFlags=; score=135}.hintValue) | 135 | none |
| São José do Rio Preto | SJP | host | $(@{city=São José do Rio Preto; iata=SJP; hintType=host; hintValue=famerp.br:443; expectedColo=SJP; source=FAMERP - medical school, São José do Rio Preto; riskFlags=; score=135}.hintValue) | 135 | none |
| Sorocaba | SOD | host | $(@{city=Sorocaba; iata=SOD; hintType=host; hintValue=uniso.br:443; expectedColo=SOD; source=UNISO - private university in Sorocaba; riskFlags=; score=135}.hintValue) | 135 | none |
| Salvador | SSA | host | $(@{city=Salvador; iata=SSA; hintType=host; hintValue=tjba.jus.br:443; expectedColo=SSA; source=Tribunal de Justiça da Bahia; riskFlags=; score=135}.hintValue) | 135 | none |
| Uberlândia | UDI | host | $(@{city=Uberlândia; iata=UDI; hintType=host; hintValue=ufu.br:443; expectedColo=UDI; source=UFU - federal university, Uberlândia; riskFlags=; score=135}.hintValue) | 135 | none |
| Campinas | VCP | host | $(@{city=Campinas; iata=VCP; hintType=host; hintValue=prefeitura.sp.gov.br:443; expectedColo=VCP; source=Prefeitura de Campinas; riskFlags=; score=135}.hintValue) | 135 | none |
| Vitória | VIX | host | $(@{city=Vitória; iata=VIX; hintType=host; hintValue=ufes.br:443; expectedColo=VIX; source=UFES - federal university, Vitória (Espírito Santo); riskFlags=NOT_SINGLE_HOMED; score=115}.hintValue) | 115 | NOT_SINGLE_HOMED |
| Chapecó | XAP | host | $(@{city=Chapecó; iata=XAP; hintType=host; hintValue=uffs.edu.br:443; expectedColo=XAP; source=UFFS - federal university, Chapecó campus; riskFlags=; score=135}.hintValue) | 135 | none |

## Notes
- Risk flags are heuristic and should be treated as advisory.
- Single IP does not guarantee strict single-homing, but multi-IP and CDN signals are strong warning signs.
- Use the Phase 9 sweep to validate actual placement outcomes (cf-placement), not reachability alone.
