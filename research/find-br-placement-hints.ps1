#Requires -Version 7.0
<#
.SYNOPSIS
  Finds suitable host endpoints for Cloudflare Workers Placement Hints
  for each Brazilian city where Cloudflare has a PoP.

.DESCRIPTION
  Cloudflare's placement.host (TCP/L4) and placement.hostname (HTTP/L7)
  require a SINGLE-HOMED host (not anycast/CDN/replicated).

  Good candidates:
  - Federal universities (unique per city)
  - Brazilian Internet Exchange (IX.br / PTT.br) looking glasses
  - Local ISP or data center endpoints
  - Government infrastructure with a fixed city datacenter

  Docs: https://developers.cloudflare.com/workers/configuration/placement/#specify-a-host-endpoint
#>

param(
  [switch]$UpdateGithubHints = $true
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ------------------------------------------------------------------
# City → Candidate hosts
# For each city we list multiple candidates (hostname:port for L4, or
# just hostname for L7 HTTP HEAD).
# Candidates are ordered: best/most likely first.
# ------------------------------------------------------------------
$cities = [ordered]@{
  'Americana'                = @{
    iata       = 'QWJ'
    candidates = @(
      @{ host = 'unisal.br:443';        type = 'L4'; note = 'Centro Universitário Salesiano - Americana campus' }
      @{ host = 'unisal.br';            type = 'L7'; note = 'Same - HTTP probe' }
      @{ host = 'fatec.sp.gov.br:443';  type = 'L4'; note = 'FATEC SP state tech colleges' }
    )
  }

  'Aracatuba'                = @{
    iata       = 'ARU'
    candidates = @(
      @{ host = 'unesp.br:443';         type = 'L4'; note = 'UNESP - has Araçatuba campus' }
      @{ host = 'unesp.br';             type = 'L7'; note = 'Same - HTTP probe' }
      @{ host = 'tce.sp.gov.br:443';    type = 'L4'; note = 'TCE SP - state court' }
    )
  }

  'Belém'                    = @{
    iata       = 'BEL'
    candidates = @(
      @{ host = 'ufpa.br:443';          type = 'L4'; note = 'Universidade Federal do Pará - Belém' }
      @{ host = 'ufpa.br';              type = 'L7'; note = 'Same - HTTP probe' }
      @{ host = 'uepa.br:443';          type = 'L4'; note = 'Universidade do Estado do Pará - Belém' }
      @{ host = 'mp.pa.gov.br:443';     type = 'L4'; note = 'Ministério Público do Pará - Belém' }
    )
  }

  'Belo Horizonte'           = @{
    iata       = 'CNF'
    candidates = @(
      @{ host = 'ufmg.br:443';          type = 'L4'; note = 'UFMG - largest university in MG' }
      @{ host = 'ufmg.br';              type = 'L7'; note = 'Same - HTTP probe' }
      @{ host = 'pucminas.br:443';      type = 'L4'; note = 'PUC Minas - BH campus' }
      @{ host = 'pbh.gov.br:443';       type = 'L4'; note = 'Prefeitura de BH' }
      @{ host = 'almg.gov.br:443';      type = 'L4'; note = 'Assembleia Legislativa de MG' }
    )
  }

  'Blumenau'                 = @{
    iata       = 'BNU'
    candidates = @(
      @{ host = 'furb.br:443';          type = 'L4'; note = 'Universidade Regional de Blumenau' }
      @{ host = 'furb.br';              type = 'L7'; note = 'Same - HTTP probe' }
      @{ host = 'hemosc.org.br:443';    type = 'L4'; note = 'Hemocentro SC - Blumenau (state agency)' }
    )
  }

  'Brasília'                 = @{
    iata       = 'BSB'
    candidates = @(
      @{ host = 'unb.br:443';           type = 'L4'; note = 'Universidade de Brasília' }
      @{ host = 'unb.br';               type = 'L7'; note = 'Same - HTTP probe' }
      @{ host = 'serpro.gov.br:443';    type = 'L4'; note = 'SERPRO - federal IT dept, HQ in Brasília' }
      @{ host = 'stf.jus.br:443';       type = 'L4'; note = 'Supremo Tribunal Federal' }
      @{ host = 'tcu.gov.br:443';       type = 'L4'; note = 'Tribunal de Contas da União' }
    )
  }

  'Caçador'                  = @{
    iata       = 'CFC'
    candidates = @(
      @{ host = 'uniarp.edu.br:443';    type = 'L4'; note = 'Universidade Alto Vale do Rio do Peixe - Caçador' }
      @{ host = 'uniarp.edu.br';        type = 'L7'; note = 'Same - HTTP probe' }
    )
  }

  'Campinas'                 = @{
    iata       = 'VCP'  # Viracopos airport
    candidates = @(
      @{ host = 'unicamp.br:443';       type = 'L4'; note = 'Unicamp - major university, Campinas' }
      @{ host = 'unicamp.br';           type = 'L7'; note = 'Same - HTTP probe' }
      @{ host = 'puc-campinas.edu.br:443'; type = 'L4'; note = 'PUC Campinas' }
      @{ host = 'prefeitura.sp.gov.br:443'; type = 'L4'; note = 'Prefeitura de Campinas' }
    )
  }

  'Campos dos Goytacazes'    = @{
    iata       = 'CAW'
    candidates = @(
      @{ host = 'uenf.br:443';          type = 'L4'; note = 'UENF - state university in Campos' }
      @{ host = 'uenf.br';              type = 'L7'; note = 'Same - HTTP probe' }
      @{ host = 'ifrj.edu.br:443';      type = 'L4'; note = 'IFRJ - federal institute with Campos campus' }
    )
  }

  'Chapecó'                  = @{
    iata       = 'XAP'
    candidates = @(
      @{ host = 'uffs.edu.br:443';      type = 'L4'; note = 'UFFS - federal university, Chapecó campus' }
      @{ host = 'uffs.edu.br';          type = 'L7'; note = 'Same - HTTP probe' }
      @{ host = 'unochapeco.edu.br:443'; type = 'L4'; note = 'Unochapecó - local university' }
    )
  }

  'Cuiabá'                   = @{
    iata       = 'CGB'
    candidates = @(
      @{ host = 'ufmt.br:443';          type = 'L4'; note = 'UFMT - federal university, Cuiabá' }
      @{ host = 'ufmt.br';              type = 'L7'; note = 'Same - HTTP probe' }
      @{ host = 'tjmt.jus.br:443';      type = 'L4'; note = 'Tribunal de Justiça do Mato Grosso' }
    )
  }

  'Curitiba'                 = @{
    iata       = 'CWB'
    candidates = @(
      @{ host = 'ufpr.br:443';          type = 'L4'; note = 'UFPR - major federal university, Curitiba' }
      @{ host = 'ufpr.br';              type = 'L7'; note = 'Same - HTTP probe' }
      @{ host = 'pucpr.br:443';         type = 'L4'; note = 'PUC Paraná - Curitiba' }
      @{ host = 'tjpr.jus.br:443';      type = 'L4'; note = 'Tribunal de Justiça do Paraná' }
    )
  }

  'Florianópolis'            = @{
    iata       = 'FLN'
    candidates = @(
      @{ host = 'ufsc.br:443';          type = 'L4'; note = 'UFSC - federal university, Florianópolis' }
      @{ host = 'ufsc.br';              type = 'L7'; note = 'Same - HTTP probe' }
      @{ host = 'udesc.br:443';         type = 'L4'; note = 'UDESC - state university, Florianópolis' }
      @{ host = 'tjsc.jus.br:443';      type = 'L4'; note = 'Tribunal de Justiça de SC' }
    )
  }

  'Fortaleza'                = @{
    iata       = 'FOR'
    candidates = @(
      @{ host = 'ufc.br:443';           type = 'L4'; note = 'UFC - federal university, Fortaleza' }
      @{ host = 'ufc.br';               type = 'L7'; note = 'Same - HTTP probe' }
      @{ host = 'uece.br:443';          type = 'L4'; note = 'UECE - state university, Fortaleza' }
      @{ host = 'tjce.jus.br:443';      type = 'L4'; note = 'Tribunal de Justiça do Ceará' }
    )
  }

  'Goiânia'                  = @{
    iata       = 'GYN'
    candidates = @(
      @{ host = 'ufg.br:443';           type = 'L4'; note = 'UFG - federal university, Goiânia' }
      @{ host = 'ufg.br';               type = 'L7'; note = 'Same - HTTP probe' }
      @{ host = 'pucgoias.edu.br:443';  type = 'L4'; note = 'PUC Goiás - Goiânia' }
      @{ host = 'tjgo.jus.br:443';      type = 'L4'; note = 'Tribunal de Justiça de Goiás' }
    )
  }

  'Joinville'                = @{
    iata       = 'JOI'
    candidates = @(
      @{ host = 'udesc.br:443';         type = 'L4'; note = 'UDESC - has major campus in Joinville' }
      @{ host = 'univille.edu.br:443';  type = 'L4'; note = 'UNIVILLE - private university in Joinville' }
      @{ host = 'univille.edu.br';      type = 'L7'; note = 'Same - HTTP probe' }
    )
  }

  'Juazeiro do Norte'        = @{
    iata       = 'JDO'
    candidates = @(
      @{ host = 'urca.br:443';          type = 'L4'; note = 'URCA - state university, Juazeiro do Norte campus' }
      @{ host = 'urca.br';              type = 'L7'; note = 'Same - HTTP probe' }
      @{ host = 'ufca.edu.br:443';      type = 'L4'; note = 'UFCA - federal university for Cariri region, Juazeiro do Norte' }
      @{ host = 'ufca.edu.br';          type = 'L7'; note = 'Same - HTTP probe' }
    )
  }

  'Manaus'                   = @{
    iata       = 'MAO'
    candidates = @(
      @{ host = 'ufam.edu.br:443';      type = 'L4'; note = 'UFAM - federal university, Manaus' }
      @{ host = 'ufam.edu.br';          type = 'L7'; note = 'Same - HTTP probe' }
      @{ host = 'uea.edu.br:443';       type = 'L4'; note = 'UEA - state university, Manaus' }
      @{ host = 'tjam.jus.br:443';      type = 'L4'; note = 'Tribunal de Justiça do Amazonas' }
    )
  }

  'Palmas'                   = @{
    iata       = 'PMW'
    candidates = @(
      @{ host = 'uft.edu.br:443';       type = 'L4'; note = 'UFT - federal university, Palmas (capital of Tocantins)' }
      @{ host = 'uft.edu.br';           type = 'L7'; note = 'Same - HTTP probe' }
      @{ host = 'unitins.br:443';       type = 'L4'; note = 'UNITINS - state university, Palmas' }
    )
  }

  'Porto Alegre'             = @{
    iata       = 'POA'
    candidates = @(
      @{ host = 'ufrgs.br:443';         type = 'L4'; note = 'UFRGS - major federal university, Porto Alegre' }
      @{ host = 'ufrgs.br';             type = 'L7'; note = 'Same - HTTP probe' }
      @{ host = 'pucrs.br:443';         type = 'L4'; note = 'PUCRS - Porto Alegre' }
      @{ host = 'tjrs.jus.br:443';      type = 'L4'; note = 'Tribunal de Justiça do RS' }
      @{ host = 'ntp.cais.rnp.br:123';  type = 'L4'; note = 'RNP NTP (may be anycast - skip if inconclusive)' }
    )
  }

  'Recife'                   = @{
    iata       = 'REC'
    candidates = @(
      @{ host = 'ufpe.br:443';          type = 'L4'; note = 'UFPE - major federal university, Recife' }
      @{ host = 'ufpe.br';              type = 'L7'; note = 'Same - HTTP probe' }
      @{ host = 'unicap.br:443';        type = 'L4'; note = 'UNICAP - private university in Recife' }
      @{ host = 'tjpe.jus.br:443';      type = 'L4'; note = 'Tribunal de Justiça de PE' }
    )
  }

  'Ribeirão Preto'           = @{
    iata       = 'RAO'
    candidates = @(
      @{ host = 'fmrp.usp.br:443';      type = 'L4'; note = 'USP Ribeirão Preto - medical school campus' }
      @{ host = 'fmrp.usp.br';          type = 'L7'; note = 'Same - HTTP probe' }
      @{ host = 'unaerp.br:443';        type = 'L4'; note = 'UNAERP - private university in Ribeirão Preto' }
    )
  }

  'Rio de Janeiro'           = @{
    iata       = 'GIG'
    candidates = @(
      @{ host = 'ufrj.br:443';          type = 'L4'; note = 'UFRJ - major federal university, Rio de Janeiro' }
      @{ host = 'ufrj.br';              type = 'L7'; note = 'Same - HTTP probe' }
      @{ host = 'puc-rio.br:443';       type = 'L4'; note = 'PUC-Rio - Rio de Janeiro' }
      @{ host = 'impa.br:443';          type = 'L4'; note = 'IMPA - math research institute, Rio' }
      @{ host = 'fiocruz.br:443';       type = 'L4'; note = 'Fiocruz - major biomedical research, HQ in Rio' }
    )
  }

  'Salvador'                 = @{
    iata       = 'SSA'
    candidates = @(
      @{ host = 'ufba.br:443';          type = 'L4'; note = 'UFBA - federal university, Salvador' }
      @{ host = 'ufba.br';              type = 'L7'; note = 'Same - HTTP probe' }
      @{ host = 'ucsal.br:443';         type = 'L4'; note = 'UCSal - private university in Salvador' }
      @{ host = 'tjba.jus.br:443';      type = 'L4'; note = 'Tribunal de Justiça da Bahia' }
    )
  }

  'São José do Rio Preto'    = @{
    iata       = 'SJP'
    candidates = @(
      @{ host = 'famerp.br:443';        type = 'L4'; note = 'FAMERP - medical school, São José do Rio Preto' }
      @{ host = 'famerp.br';            type = 'L7'; note = 'Same - HTTP probe' }
      @{ host = 'ibilce.unesp.br:443';  type = 'L4'; note = 'UNESP - São José do Rio Preto campus (IBILCE)' }
    )
  }

  'São José dos Campos'      = @{
    iata       = 'SJK'
    candidates = @(
      @{ host = 'ita.br:443';           type = 'L4'; note = 'ITA - Instituto Tecnológico de Aeronáutica, SJC' }
      @{ host = 'ita.br';               type = 'L7'; note = 'Same - HTTP probe' }
      @{ host = 'inpe.br:443';          type = 'L4'; note = 'INPE - space research institute, HQ in SJC' }
      @{ host = 'univap.br:443';        type = 'L4'; note = 'UNIVAP - private university in SJC' }
    )
  }

  'São Paulo'                = @{
    iata       = 'GRU'
    candidates = @(
      @{ host = 'usp.br:443';           type = 'L4'; note = 'USP - largest university in Brazil, São Paulo' }
      @{ host = 'usp.br';               type = 'L7'; note = 'Same - HTTP probe' }
      @{ host = 'pucsp.br:443';         type = 'L4'; note = 'PUC-SP - São Paulo' }
      @{ host = 'fapesp.br:443';        type = 'L4'; note = 'FAPESP - SP science foundation, HQ in SP' }
      @{ host = 'ptt.br:443';           type = 'L4'; note = 'IX.br / PTT association HQ in SP' }
    )
  }

  'Sorocaba'                 = @{
    iata       = 'SOD'
    candidates = @(
      @{ host = 'ufscar.br:443';        type = 'L4'; note = 'UFSCar - has Sorocaba campus' }
      @{ host = 'uniso.br:443';         type = 'L4'; note = 'UNISO - private university in Sorocaba' }
      @{ host = 'uniso.br';             type = 'L7'; note = 'Same - HTTP probe' }
    )
  }

  'Timbó'                    = @{
    iata       = 'NVT'  # Near Navegantes/Itajaí coastal region of SC
    candidates = @(
      @{ host = 'univali.br:443';       type = 'L4'; note = 'UNIVALI - covers Itajaí/Balneário Camboriú area near Timbó' }
      @{ host = 'univali.br';           type = 'L7'; note = 'Same - HTTP probe' }
      @{ host = 'ifc.edu.br:443';       type = 'L4'; note = 'Instituto Federal Catarinense' }
    )
  }

  'Uberlândia'               = @{
    iata       = 'UDI'
    candidates = @(
      @{ host = 'ufu.br:443';           type = 'L4'; note = 'UFU - federal university, Uberlândia' }
      @{ host = 'ufu.br';               type = 'L7'; note = 'Same - HTTP probe' }
      @{ host = 'unitri.edu.br:443';    type = 'L4'; note = 'UNITRI - private university in Uberlândia' }
    )
  }

  'Vitória'                  = @{
    iata       = 'VIX'
    candidates = @(
      @{ host = 'ufes.br:443';          type = 'L4'; note = 'UFES - federal university, Vitória (Espírito Santo)' }
      @{ host = 'ufes.br';              type = 'L7'; note = 'Same - HTTP probe' }
      @{ host = 'tjes.jus.br:443';      type = 'L4'; note = 'Tribunal de Justiça do Espírito Santo' }
    )
  }
}

# ------------------------------------------------------------------
# Helper: parse host and port from candidate
# ------------------------------------------------------------------
function Parse-HostSpec {
  param([string]$HostSpec)
  $parts = $HostSpec -split ':'
  $hostNamePart = $parts[0]
  $port = if ($parts.Count -gt 1) { [int]$parts[1] } else { 443 }
  [pscustomobject]@{
    Hostname = $hostNamePart
    Port = $port
  }
}

# ------------------------------------------------------------------
# Helper: DNS profile (IP count + CNAME chain + CDN hints)
# ------------------------------------------------------------------
function Get-DnsProfile {
  param([string]$Hostname)

  $a = @()
  $aaaa = @()
  $cname = @()

  try {
    $a = @(Resolve-DnsName -Name $Hostname -Type A -ErrorAction Stop | Where-Object { $_.Type -eq 'A' } | Select-Object -ExpandProperty IPAddress -Unique)
  } catch {}

  try {
    $aaaa = @(Resolve-DnsName -Name $Hostname -Type AAAA -ErrorAction Stop | Where-Object { $_.Type -eq 'AAAA' } | Select-Object -ExpandProperty IPAddress -Unique)
  } catch {}

  try {
    $cname = @(Resolve-DnsName -Name $Hostname -Type CNAME -ErrorAction Stop | Where-Object { $_.Type -eq 'CNAME' } | Select-Object -ExpandProperty NameHost -Unique)
  } catch {}

  $cdnDomainPattern = '(cloudflare|cloudfront|akamai|edgekey|fastly|cdn|edgesuite|incapdns|sucuri|stackpath|b-cdn\.net)'
  $allNames = @($Hostname) + $cname
  $cdnNameHit = @($allNames | Where-Object { $_ -match $cdnDomainPattern })

  $ips = @($a + $aaaa | Select-Object -Unique)
  $ipCount = $ips.Count
  $singleIpLikely = ($ipCount -eq 1)
  $multiIpLikely = ($ipCount -ge 3)
  $cdnHint = ($cdnNameHit.Count -gt 0)

  [pscustomobject]@{
    Hostname = $Hostname
    A = $a
    AAAA = $aaaa
    CNAME = $cname
    IpCount = $ipCount
    SingleIpLikely = $singleIpLikely
    MultiIpLikely = $multiIpLikely
    CdnHint = $cdnHint
    CdnNameHits = $cdnNameHit
  }
}

# ------------------------------------------------------------------
# Helper: test TCP connectivity (placement.host style)
# ------------------------------------------------------------------
function Test-TcpHost {
  param(
    [string]$HostPort,
    [int]$TimeoutMs = 3000
  )
  $parsed = Parse-HostSpec -HostSpec $HostPort
  try {
    $tcp = [System.Net.Sockets.TcpClient]::new()
    $task = $tcp.ConnectAsync($parsed.Hostname, $parsed.Port)
    if ($task.Wait($TimeoutMs)) {
      $tcp.Close()
      return [pscustomobject]@{ OK = $true; Status = 'OK' }
    }
    $tcp.Close()
    return [pscustomobject]@{ OK = $false; Status = 'TIMEOUT' }
  } catch {
    return [pscustomobject]@{ OK = $false; Status = 'FAIL' }
  }
}

# ------------------------------------------------------------------
# Helper: test HTTP HEAD and collect headers (placement.hostname style)
# ------------------------------------------------------------------
function Test-HttpHost {
  param(
    [string]$Hostname,
    [int]$TimeoutSec = 5
  )

  foreach ($scheme in @('https', 'http')) {
    $url = "${scheme}://$Hostname/"
    try {
      $resp = Invoke-WebRequest -Uri $url -Method HEAD -TimeoutSec $TimeoutSec -SkipHttpErrorCheck -MaximumRedirection 0 -SkipCertificateCheck
      return [pscustomobject]@{
        OK = $true
        StatusCode = [int]$resp.StatusCode
        Status = "HTTP $([int]$resp.StatusCode)"
        Headers = $resp.Headers
        Url = $url
      }
    } catch {
      continue
    }
  }

  return [pscustomobject]@{
    OK = $false
    StatusCode = $null
    Status = 'FAIL'
    Headers = $null
    Url = $null
  }
}

# ------------------------------------------------------------------
# Helper: CDN header detection
# ------------------------------------------------------------------
function Get-CdnHeaderSignals {
  param($Headers)

  if ($null -eq $Headers) {
    return [pscustomobject]@{ CdnHeaderHint = $false; Evidence = @() }
  }

  $evidence = @()
  $pairs = @(
    @{ Key = 'Server'; Pattern = '(cloudflare|cloudfront|akamai|fastly|imperva|sucuri)' }
    @{ Key = 'Via'; Pattern = '(varnish|akamai|cloudfront|fastly)' }
    @{ Key = 'X-Cache'; Pattern = '(hit|miss|cdn)' }
    @{ Key = 'CF-RAY'; Pattern = '.+' }
    @{ Key = 'CF-Cache-Status'; Pattern = '.+' }
  )

  foreach ($pair in $pairs) {
    if ($Headers.ContainsKey($pair.Key)) {
      $v = [string]$Headers[$pair.Key]
      if ($v -match $pair.Pattern) {
        $evidence += "$($pair.Key)=$v"
      }
    }
  }

  [pscustomobject]@{
    CdnHeaderHint = ($evidence.Count -gt 0)
    Evidence = $evidence
  }
}

# ------------------------------------------------------------------
# Helper: candidate scoring
# ------------------------------------------------------------------
function Get-CandidateScore {
  param(
    [bool]$Reachable,
    [string]$Type,
    [bool]$CdnNameHint,
    [bool]$CdnHeaderHint,
    [int]$IpCount,
    [bool]$SingleIpLikely
  )

  if (-not $Reachable) {
    return -1000
  }

  $score = 100

  # Prefer L4 for explicit placement.host unless L7 is clearly better.
  if ($Type -eq 'L4') { $score += 15 }

  if ($SingleIpLikely) { $score += 20 }
  if ($IpCount -ge 3) { $score -= 25 }
  if ($CdnNameHint) { $score -= 50 }
  if ($CdnHeaderHint) { $score -= 40 }

  return $score
}

# ------------------------------------------------------------------
# Main: test candidates and build results
# ------------------------------------------------------------------
$results = [ordered]@{}

Write-Host "`n=== Cloudflare Workers Placement Hints - Brazil PoP Host Finder ===" -ForegroundColor Cyan
Write-Host "Testing $($cities.Count) cities with $(($cities.Values | ForEach-Object { $_.candidates.Count } | Measure-Object -Sum).Sum) total candidates...`n" -ForegroundColor Gray

foreach ($city in $cities.GetEnumerator()) {
  $cityName = $city.Key
  $cityData = $city.Value
  $iata = $cityData.iata

  Write-Host "[$iata] $cityName" -ForegroundColor Yellow -NoNewline

  $cityResults = @()

  foreach ($candidate in $cityData.candidates) {
    $hostSpec = $candidate.host
    $type = $candidate.type
    $note = $candidate.note
    $parsed = Parse-HostSpec -HostSpec $hostSpec

    $dnsProfile = Get-DnsProfile -Hostname $parsed.Hostname

    $ok = $false
    $status = 'FAIL'
    $httpStatusCode = $null
    $cdnHeaderHint = $false
    $cdnEvidence = @()

    if ($type -eq 'L4') {
      $tcp = Test-TcpHost -HostPort $hostSpec
      $ok = $tcp.OK
      $status = $tcp.Status
    } else {
      $http = Test-HttpHost -Hostname $hostSpec
      $ok = $http.OK
      $status = $http.Status
      $httpStatusCode = $http.StatusCode

      $headerSignals = Get-CdnHeaderSignals -Headers $http.Headers
      $cdnHeaderHint = $headerSignals.CdnHeaderHint
      $cdnEvidence = $headerSignals.Evidence
    }

    $singleHomedLikely = $dnsProfile.SingleIpLikely -and -not $dnsProfile.CdnHint -and -not $cdnHeaderHint
    $riskFlags = @()
    if ($dnsProfile.CdnHint) { $riskFlags += 'CDN_NAME' }
    if ($cdnHeaderHint) { $riskFlags += 'CDN_HEADER' }
    if ($dnsProfile.MultiIpLikely) { $riskFlags += 'MULTI_IP' }
    if (-not $singleHomedLikely) { $riskFlags += 'NOT_SINGLE_HOMED' }

    $score = Get-CandidateScore -Reachable:$ok -Type $type -CdnNameHint:$dnsProfile.CdnHint -CdnHeaderHint:$cdnHeaderHint -IpCount $dnsProfile.IpCount -SingleIpLikely:$dnsProfile.SingleIpLikely

    Write-Host '.' -NoNewline

    $cityResults += [pscustomobject]@{
      City = $cityName
      IATA = $iata
      Host = $hostSpec
      Type = $type
      Status = $status
      HttpStatusCode = $httpStatusCode
      OK = $ok
      Score = $score
      SingleHomedLikely = $singleHomedLikely
      CdnNameHint = $dnsProfile.CdnHint
      CdnHeaderHint = $cdnHeaderHint
      IpCount = $dnsProfile.IpCount
      RiskFlags = ($riskFlags -join ';')
      DnsA = ($dnsProfile.A -join '|')
      DnsAAAA = ($dnsProfile.AAAA -join '|')
      DnsCNAME = ($dnsProfile.CNAME -join '|')
      CdnEvidence = ($cdnEvidence -join '|')
      Note = $note
    }
  }

  $results[$cityName] = $cityResults
  Write-Host " done" -ForegroundColor Gray
}

# ------------------------------------------------------------------
# Build recommendations
# ------------------------------------------------------------------
Write-Host "`n`n=== RESULTS ===" -ForegroundColor Cyan
$recommendations = [ordered]@{}

foreach ($city in $results.GetEnumerator()) {
  $cityName = $city.Key
  $entries = @($city.Value)
  $iata = $entries[0].IATA

  $working = @($entries | Where-Object { $_.OK })
  $safeWorking = @($working | Where-Object { $_.SingleHomedLikely })

  Write-Host "`n[$iata] $cityName" -ForegroundColor Yellow

  foreach ($w in ($working | Sort-Object Score -Descending)) {
    $directive = if ($w.Type -eq 'L4') { 'host' } else { 'hostname' }
    $risk = if ([string]::IsNullOrWhiteSpace($w.RiskFlags)) { 'none' } else { $w.RiskFlags }
    Write-Host "  ✓ placement.$directive = `"$($w.Host)`"  (score=$($w.Score), risk=$risk)" -ForegroundColor Green
    Write-Host "    # $($w.Note)" -ForegroundColor Gray
  }

  $best = $null
  if ($safeWorking.Count -gt 0) {
    $best = $safeWorking | Sort-Object Score -Descending | Select-Object -First 1
  } elseif ($working.Count -gt 0) {
    $best = $working | Sort-Object Score -Descending | Select-Object -First 1
  }

  if ($null -eq $best) {
    Write-Host "  ✗ No reachable hosts found" -ForegroundColor Red
  }

  $recommendations[$cityName] = $best
}

# ------------------------------------------------------------------
# Save outputs under research/
# ------------------------------------------------------------------
$allResults = @($results.Values | ForEach-Object { $_ })
$csvPath = Join-Path $PSScriptRoot 'br-placement-hints-results.csv'
$allResults | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8

$recommendedRows = @()
foreach ($cityName in $cities.Keys) {
  $best = $recommendations[$cityName]
  if ($null -eq $best) { continue }

  $hintType = if ($best.Type -eq 'L4') { 'host' } else { 'hostname' }
  $recommendedRows += [pscustomobject]@{
    city = $cityName
    iata = $cities[$cityName].iata
    hintType = $hintType
    hintValue = $best.Host
    expectedColo = $cities[$cityName].iata
    source = $best.Note
    riskFlags = $best.RiskFlags
    score = $best.Score
  }
}

$jsonPath = Join-Path $PSScriptRoot 'placement-hints.json'
($recommendedRows | ConvertTo-Json -Depth 4) | Set-Content -Path $jsonPath -Encoding UTF8

$reportPath = Join-Path $PSScriptRoot 'CF_PLACEMENT_HINTS.md'
$total = $cities.Count
$recommendedCount = $recommendedRows.Count
$safeCount = @($recommendedRows | Where-Object { [string]::IsNullOrWhiteSpace($_.riskFlags) -or $_.riskFlags -eq 'none' }).Count

$md = @()
$md += '# Cloudflare Placement Hints - Brazil Research'
$md += ''
$md += "Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss zzz')"
$md += ''
$md += '## Methodology'
$md += '- Test candidate reachability (L4 TCP and L7 HTTP HEAD).'
$md += '- Build DNS profile (A/AAAA/CNAME count and CDN-like CNAME patterns).'
$md += '- Detect CDN proxy hints in HTTP headers when L7 is tested.'
$md += '- Score candidates and prefer likely single-homed endpoints.'
$md += ''
$md += '## Summary'
$md += "- Cities in matrix: $total"
$md += "- Cities with recommendations: $recommendedCount"
$md += "- Recommendations without risk flags: $safeCount"
$md += ''
$md += '## Recommended Hints'
$md += ''
$md += '| City | IATA | Hint Type | Hint Value | Score | Risk Flags |'
$md += '|------|------|-----------|------------|-------|------------|'
foreach ($row in ($recommendedRows | Sort-Object iata)) {
  $risk = if ([string]::IsNullOrWhiteSpace($row.riskFlags)) { 'none' } else { $row.riskFlags }
  $md += "| $($row.city) | $($row.iata) | $($row.hintType) | `$($row.hintValue)` | $($row.score) | $risk |"
}

$md += ''
$md += '## Notes'
$md += '- Risk flags are heuristic and should be treated as advisory.'
$md += '- Single IP does not guarantee strict single-homing, but multi-IP and CDN signals are strong warning signs.'
$md += '- Use the Phase 9 sweep to validate actual placement outcomes (cf-placement), not reachability alone.'

$md | Set-Content -Path $reportPath -Encoding UTF8

if ($UpdateGithubHints.IsPresent) {
  $repoRoot = Resolve-Path (Join-Path $PSScriptRoot '..')
  $githubHintsPath = Join-Path $repoRoot '.github/placement-hints.json'
  $phase9Rows = @($recommendedRows | Select-Object city, iata, hintType, hintValue, expectedColo, source)
  ($phase9Rows | ConvertTo-Json -Depth 4) | Set-Content -Path $githubHintsPath -Encoding UTF8
  Write-Host "Updated Phase 9 matrix source: $githubHintsPath" -ForegroundColor Cyan
}

Write-Host "`nSaved CSV: $csvPath" -ForegroundColor Cyan
Write-Host "Saved report: $reportPath" -ForegroundColor Cyan
Write-Host "Saved machine-readable hints: $jsonPath" -ForegroundColor Cyan
