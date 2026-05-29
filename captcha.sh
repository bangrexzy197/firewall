#!/bin/bash
DIR="/var/www/pterodactyl/public"
if [ ! -d "$DIR" ]; then
  DIR=$(find /var/www -type d -name "public" 2>/dev/null | grep "pterodactyl" | head -n 1 || true)
fi

[ -z "${DIR:-}" ] && exit 1
cd "$DIR" 2>/dev/null || exit 1

if [ -f "index.php" ] && [ ! -f "index.php.bak" ]; then
  cp index.php index.php.bak
  echo "✅ Backup created: $DIR/index.php.bak"
elif [ -f "index.php" ] && [ -f "index.php.bak" ]; then
  echo "✅ Backup already exists, skipping backup"
else
  echo "❌ index.php not found in $DIR"
  exit 1
fi

cat <<'HTML_EOF' > 429.php
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>429 - Too Many Requests</title>

<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.2/css/all.min.css">

<style>
*{
    margin:0;
    padding:0;
    box-sizing:border-box;
    font-family:Arial,sans-serif;
}

body{
    background:#000;
    height:100vh;
    display:flex;
    justify-content:center;
    align-items:center;
    text-align:center;
    color:#fff;
}

.box{
    width:90%;
    max-width:320px;
}

h1{
    font-size:20px;
    font-weight:700;
    margin-bottom:25px;
}

button{
    width:100%;
    padding:14px;
    border:none;
    border-radius:35px;
    background:linear-gradient(135deg,#2563eb,#3b82f6);
    color:#fff;
    font-size:17px;
    font-weight:600;
    cursor:pointer;
    transition:.2s;
    box-shadow:0 0 20px rgba(59,130,246,.35);
}

button i{
    margin-right:8px;
}

button:active{
    transform:scale(.98);
}
</style>
</head>
<body>

<div class="box">
    <h1>Too Many Requests</h1>

    <button onclick="location.reload()">
        <i class="fa-solid fa-rotate-right"></i>
        Refresh page
    </button>
</div>

</body>
</html>

HTML_EOF
cat <<'PHP_EOF' > challenge.php
<?php
error_reporting(0);
session_start();

$ip = $_SERVER['HTTP_CF_CONNECTING_IP'] ?? $_SERVER['REMOTE_ADDR'] ?? '0.0.0.0';
$challengeFile = sys_get_temp_dir() . "/challenge_" . md5($ip);
$verifiedFile = sys_get_temp_dir() . "/verified_" . md5($ip);
$jsChallengeFile = sys_get_temp_dir() . "/jschallenge_" . md5($ip);

if (file_exists($verifiedFile) && (time() - filemtime($verifiedFile)) < 900) {
    if (isset($_GET['check']) && $_GET['check'] == 1) {
        header('Content-Type: application/json');
        echo json_encode(['verified' => true]);
        exit;
    }
    if (strpos($_SERVER['REQUEST_URI'], 'challenge.php') === false && strpos($_SERVER['REQUEST_URI'], '_challenge_verifikasi') === false) {
        return;
    }
}

if (!file_exists($jsChallengeFile)) {
    $jsChallenge = [
        'challenge' => bin2hex(random_bytes(16)),
        'answer' => null,
        'expires' => time() + 120
    ];
    file_put_contents($jsChallengeFile, json_encode($jsChallenge));
} else {
    $jsChallenge = json_decode(file_get_contents($jsChallengeFile), true);
    if ($jsChallenge['expires'] < time()) {
        $jsChallenge = [
            'challenge' => bin2hex(random_bytes(16)),
            'answer' => null,
            'expires' => time() + 120
        ];
        file_put_contents($jsChallengeFile, json_encode($jsChallenge));
    }
}

if (!file_exists($challengeFile)) {
    $challenge = [
        'token' => bin2hex(random_bytes(32)),
        'expires' => time() + 120,
        'verified' => false
    ];
    file_put_contents($challengeFile, json_encode($challenge));
} else {
    $challenge = json_decode(file_get_contents($challengeFile), true);
    if ($challenge['expires'] < time()) {
        $challenge = [
            'token' => bin2hex(random_bytes(32)),
            'expires' => time() + 120,
            'verified' => false
        ];
        file_put_contents($challengeFile, json_encode($challenge));
    }
}

if ($_SERVER['REQUEST_METHOD'] === 'GET' && isset($_GET['token']) && isset($_GET['js_answer'])) {

    $jsValid = false;

    if ($_GET['js_answer'] === $jsChallenge['challenge']) {
        $jsValid = true;
    }

    if ($_GET['token'] === $challenge['token'] && $jsValid) {

        $challenge['verified'] = true;
        file_put_contents($challengeFile, json_encode($challenge));
        file_put_contents($verifiedFile, time());

        header('Content-Type: application/json');

        echo json_encode([
            'success' => true,
            'message' => 'Verification successful'
        ]);

        exit;
    }

    header('Content-Type: application/json');

    echo json_encode([
        'success' => false,
        'error' => 'Invalid verification'
    ]);

    exit;
}

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $input = json_decode(file_get_contents('php://input'), true);
    
    $jsValid = false;
    if (isset($input['js_answer']) && $input['js_answer'] === $jsChallenge['challenge']) {
        $jsValid = true;
    }
    
    if ($input['token'] === $challenge['token'] && $jsValid) {
        $challenge['verified'] = true;
        file_put_contents($challengeFile, json_encode($challenge));
        file_put_contents($verifiedFile, time());
        
        echo json_encode([
            'success' => true,
            'message' => 'Verification successful'
        ]);
        exit;
    }
    
    echo json_encode([
        'success' => false,
        'error' => 'Invalid verification'
    ]);
    exit;
}

header('Content-Type: text/html; charset=utf-8');
?>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Just a moment...</title>
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600&display=swap" rel="stylesheet">
<style>
* {
    margin: 0;
    padding: 0;
    box-sizing: border-box;
    font-family: 'Inter', sans-serif;
}

body {
    height: 100vh;
    display: flex;
    justify-content: center;
    align-items: center;
    background: #05070b;
}

.recaptcha-box {
    width: 390px;
    padding: 18px;
    border-radius: 22px;
    backdrop-filter: blur(16px);
    background: rgba(15, 23, 42, 0.75);
    border: 1px solid rgba(255, 255, 255, 0.08);
    box-shadow: 0 10px 50px rgba(0, 0, 0, 0.55), inset 0 1px 0 rgba(255, 255, 255, 0.05);
}

.top {
    display: flex;
    align-items: center;
    justify-content: space-between;
}

.left {
    display: flex;
    align-items: center;
    gap: 16px;
}

.checkbox {
    width: 38px;
    height: 38px;
    border-radius: 12px;
    border: 2px solid rgba(255, 255, 255, 0.18);
    background: rgba(255, 255, 255, 0.03);
    display: flex;
    align-items: center;
    justify-content: center;
    cursor: pointer;
    transition: 0.3s;
    position: relative;
    overflow: hidden;
}

.checkbox:hover {
    transform: scale(1.06);
    border-color: #60a5fa;
    box-shadow: 0 0 25px rgba(96, 165, 250, 0.25);
}

.checkbox.loading {
    border-color: #60a5fa;
    box-shadow: 0 0 30px rgba(59, 130, 246, 0.35), inset 0 0 20px rgba(59, 130, 246, 0.08);
}

.checkbox.checked {
    background: linear-gradient(135deg, #2563eb, #3b82f6);
    border-color: #60a5fa;
    box-shadow: 0 0 30px rgba(59, 130, 246, 0.55), inset 0 0 15px rgba(255, 255, 255, 0.15);
}

.checkbox svg {
    width: 20px;
    height: 20px;
    stroke: white;
    stroke-width: 3;
    fill: none;
    stroke-linecap: round;
    stroke-linejoin: round;
    opacity: 0;
    transform: scale(0.5);
    transition: 0.3s;
    position: absolute;
}

.checkbox.checked svg {
    opacity: 1;
    transform: scale(1);
}

.spinner {
    position: absolute;
    width: 22px;
    height: 22px;
    border-radius: 50%;
    border: 2px solid rgba(255, 255, 255, 0.12);
    border-top: 2px solid #60a5fa;
    border-right: 2px solid #2563eb;
    opacity: 0;
    animation: spin 0.8s linear infinite;
    box-shadow: 0 0 15px rgba(96, 165, 250, 0.45);
}

.checkbox.loading .spinner {
    opacity: 1;
}

.checkbox.loading svg {
    opacity: 0;
}

@keyframes spin {
    100% { transform: rotate(360deg); }
}

.text-wrap {
    display: flex;
    flex-direction: column;
}

.main-text {
    color: white;
    font-size: 18px;
    font-weight: 600;
}

.sub-text {
    margin-top: 2px;
    font-size: 12px;
    color: #94a3b8;
}

.right {
    display: flex;
    flex-direction: column;
    align-items: center;
    gap: 4px;
}

.logo-box {
    width: 44px;
    height: 44px;
    border-radius: 14px;
    display: flex;
    justify-content: center;
    align-items: center;
    background: rgba(255, 255, 255, 0.05);
    border: 1px solid rgba(255, 255, 255, 0.06);
}

.logo-box img {
    width: 28px;
    height: 28px;
    filter: drop-shadow(0 0 6px rgba(255, 255, 255, 0.15));
}

.small {
    font-size: 10px;
    color: #94a3b8;
}

.error-message {
    margin-top: 15px;
    padding: 12px;
    border-radius: 12px;
    background: rgba(220, 38, 38, 0.15);
    border: 1px solid rgba(220, 38, 38, 0.3);
    color: #ef4444;
    font-size: 12px;
    text-align: center;
    display: none;
}
</style>
</head>
<body>
<div class="recaptcha-box">
    <div class="top">
        <div class="left">
            <div class="checkbox" id="check">
                <div class="spinner"></div>
                <svg viewBox="0 0 24 24"><path d="M5 13l4 4L19 7"/></svg>
            </div>
            <div class="text-wrap">
                <div class="main-text">I'm not a robot</div>
                <div class="sub-text">Security verification required</div>
            </div>
        </div>
        <div class="right">
            <div class="logo-box"><img src="https://www.gstatic.com/recaptcha/api2/logo_48.png" alt="reCAPTCHA"></div>
            <div class="small">reCAPTCHA</div>
        </div>
    </div>
    <div class="error-message" id="errorMsg"></div>
</div>
<script>
const check = document.getElementById("check");
const errorMsg = document.getElementById("errorMsg");
let loading = false;
const token = "<?php echo $challenge['token']; ?>";
const jsChallenge = "<?php echo $jsChallenge['challenge']; ?>";

function solveJSChallenge() {
    return jsChallenge;
}

async function checkBrowser() {
    const checks = {
        cookiesEnabled: navigator.cookieEnabled,
        userAgent: navigator.userAgent,
        language: navigator.language,
        platform: navigator.platform,
        hardwareConcurrency: navigator.hardwareConcurrency || 0,
        deviceMemory: navigator.deviceMemory || 0,
        maxTouchPoints: navigator.maxTouchPoints || 0,
        doNotTrack: navigator.doNotTrack,
        productSub: navigator.productSub,
        vendor: navigator.vendor
    };
    
    if (navigator.webdriver === true || navigator.userAgent.includes('Headless')) {
        checks.isHeadless = true;
    }

    try {
        const canvas = document.createElement('canvas');
        canvas.width = 200;
        canvas.height = 50;
        const ctx = canvas.getContext('2d');
        ctx.fillStyle = '#000';
        ctx.fillRect(0, 0, canvas.width, canvas.height);
        ctx.fillStyle = '#fff';
        ctx.font = '14px Arial';
        ctx.fillText('test', 10, 25);
        ctx.fillStyle = '#f00';
        ctx.fillRect(50, 20, 30, 20);
        checks.canvasFingerprint = canvas.toDataURL();
    } catch(e) {}

    try {
        const canvas = document.createElement('canvas');
        const gl = canvas.getContext('webgl') || canvas.getContext('experimental-webgl');
        if (gl) {
            const debugInfo = gl.getExtension('WEBGL_debug_renderer_info');
            if (debugInfo) {
                checks.webglVendor = gl.getParameter(debugInfo.UNMASKED_VENDOR_WEBGL);
                checks.webglRenderer = gl.getParameter(debugInfo.UNMASKED_RENDERER_WEBGL);
            }
        }
    } catch(e) {}

    try {
        const audioCtx = new (window.AudioContext || window.webkitAudioContext)();
        const analyser = audioCtx.createAnalyser();
        const oscillator = audioCtx.createOscillator();
        oscillator.connect(analyser);
        oscillator.start();
        const dataArray = new Uint8Array(analyser.frequencyBinCount);
        analyser.getByteFrequencyData(dataArray);
        checks.audioFingerprint = dataArray.slice(0, 10).join(',');
        oscillator.stop();
        audioCtx.close();
    } catch(e) {}

    try {
        if (navigator.getBattery) {
            const battery = await navigator.getBattery();
            checks.batteryLevel = battery.level;
            checks.batteryCharging = battery.charging;
        }
    } catch(e) {}

    checks.timezone = Intl.DateTimeFormat().resolvedOptions().timeZone;
    checks.screenResolution = `${screen.width}x${screen.height}`;
    checks.screenColorDepth = screen.colorDepth;
    checks.screenPixelDepth = screen.pixelDepth;

    checks.languages = navigator.languages;

    try {
        const tlsTest = await fetch('https://www.cloudflare.com/cdn-cgi/trace', { method: 'GET', cache: 'no-store' });
        const text = await tlsTest.text();
        const match = text.match(/tls=([^\n]+)/);
        if (match) checks.tlsVersion = match[1];
        const cipherMatch = text.match(/cipher=([^\n]+)/);
        if (cipherMatch) checks.cipherSuite = cipherMatch[1];
    } catch(e) {}
    
    return checks;
}

check.addEventListener("click", async () => {
    if (loading || check.classList.contains("checked")) return;
    
    loading = true;
    check.classList.add("loading");
    errorMsg.style.display = "none";
    
    const browserChecks = await checkBrowser();
    const jsAnswer = solveJSChallenge();
    
    let isValid = true;
    let reason = '';
    
    if (browserChecks.isHeadless === true) {
        isValid = false;
        reason = 'Headless browser detected';
    } else if (!browserChecks.cookiesEnabled) {
        isValid = false;
        reason = 'Cookies disabled';
    } else if (browserChecks.hardwareConcurrency === 0) {
        isValid = false;
        reason = 'Invalid hardware concurrency';
    }
    
    if (!isValid) {
        setTimeout(() => {
            check.classList.remove("loading");
            loading = false;
            errorMsg.style.display = "block";
            errorMsg.innerHTML = "❌ Verification failed: " + reason;
            setTimeout(() => errorMsg.style.display = "none", 3000);
        }, 500);
        return;
    }
    
    try {
        const response = await fetch(window.location.href, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ token: token, js_answer: jsAnswer, browser_data: browserChecks })
        });
        const result = await response.json();
        
        if (result.success) {
            setTimeout(() => {
                check.classList.remove("loading");
                check.classList.add("checked");
                loading = false;
                errorMsg.style.display = "block";
                errorMsg.style.background = "rgba(34,197,94,.15)";
                errorMsg.style.borderColor = "rgba(34,197,94,.3)";
                errorMsg.style.color = "#22c55e";
                errorMsg.innerHTML = "✓ Verification successful! Redirecting...";
                setTimeout(() => window.location.href = "/", 1500);
            }, 500);
        } else {
            throw new Error(result.error || "Verification failed");
        }
    } catch(err) {
        setTimeout(() => {
            check.classList.remove("loading");
            loading = false;
            errorMsg.style.display = "block";
            errorMsg.innerHTML = "❌ Verification failed: " + err.message;
            setTimeout(() => errorMsg.style.display = "none", 3000);
        }, 500);
    }
});
</script>
</body>
</html>
<?php
exit;
PHP_EOF

cat <<'PHP_EOF' > index.php
<?php
session_start();

$ip = $_SERVER['HTTP_CF_CONNECTING_IP'] ?? $_SERVER['REMOTE_ADDR'] ?? '0.0.0.0';

if (strpos($ip, ',') !== false) {
    $ip = explode(',', $ip)[0];
}

if (!filter_var($ip, FILTER_VALIDATE_IP)) {
    $ip = $_SERVER['REMOTE_ADDR'] ?? '0.0.0.0';
}

$ua = trim($_SERVER['HTTP_USER_AGENT'] ?? '');
$uri = $_SERVER['REQUEST_URI'] ?? '';
$path = parse_url($uri, PHP_URL_PATH) ?? '/';
$method = $_SERVER['REQUEST_METHOD'] ?? 'GET';

$whitelistIps = [
    '168.144.129.131',
    '114.10.134.224',
    '68.183.228.145'
];

$whitelistUa = [
    'Wings',
    'Go-http-client',
    'Docker',
    'kube-probe',
    'cadvisor',
    'prometheus',
    'grafana',
    'consul',
    'nomad',
    'vault',
    'traefik',
    'nginx-ingress',
    'istio',
    'envoy',
    'linkerd'
];

$whitelistPaths = [
    '/health',
    '/healthz',
    '/ready',
    '/live',
    '/metrics',
    '/ping',
    '/status'
];

$isApi = strpos($path, '/api/') === 0 || strpos($path, '/api/client/') === 0 || strpos($path, '/api/application/') === 0;
$isWings = stripos($ua, 'Wings') !== false || stripos($ua, 'Go-http-client') !== false;
$isDocker = stripos($ua, 'Docker') !== false || stripos($ua, 'containerd') !== false;
$isWhitelistedIp = in_array($ip, $whitelistIps);
$isWhitelistedUa = in_array($ua, $whitelistUa);
$isWhitelistedPath = in_array($path, $whitelistPaths) || strpos($path, '/.well-known/') === 0;

$skipVerifikasi = $isApi || $isWings || $isDocker || $isWhitelistedIp || $isWhitelistedUa || $isWhitelistedPath || $path === '/favicon.ico' || $path === '/challenge.php';

if (!$skipVerifikasi) {
    $verifiedFile = sys_get_temp_dir() . "/verified_" . md5($ip);
    $isVerified = file_exists($verifiedFile) && (time() - filemtime($verifiedFile)) < 900;
    
    if (!$isVerified) {
        require __DIR__ . '/challenge.php';
        exit;
    }
}

$packetCountFile = sys_get_temp_dir() . "/packet_" . md5($ip);
$maxPackets = 500;
$packetWindow = 10;

if (!file_exists($packetCountFile)) {
    $packetData = ["count" => 1, "time" => time()];
    file_put_contents($packetCountFile, json_encode($packetData));
} else {
    $packetData = json_decode(file_get_contents($packetCountFile), true);
    if (!is_array($packetData)) {
        $packetData = ["count" => 0, "time" => time()];
    }
    
    if (time() - $packetData["time"] > $packetWindow) {
        $packetData = ["count" => 1, "time" => time()];
    } else {
        $packetData["count"]++;
    }
    
    file_put_contents($packetCountFile, json_encode($packetData));
}

if ($packetData["count"] > $maxPackets && !$skipVerifikasi) {
    banIpIptables($ip, "Packet rate exceeded: {$packetData['count']} packets in {$packetWindow} sec");
    http_response_code(429);
    die("🚫 Packet rate limit exceeded.");
}

$maxBodySize = 1024 * 1024;
$contentLength = (int)($_SERVER['CONTENT_LENGTH'] ?? 0);

if ($contentLength > $maxBodySize && !$skipVerifikasi) {
    banIpIptables($ip, "Request too large: {$contentLength} bytes");
    http_response_code(413);
    die("🚫 Request entity too large.");
}

$concurrentFile = sys_get_temp_dir() . "/concurrent_" . md5($ip);

if (!file_exists($concurrentFile)) {
    $concurrentData = ["requests" => 1, "start_time" => time()];
    file_put_contents($concurrentFile, json_encode($concurrentData));
} else {
    $concurrentData = json_decode(file_get_contents($concurrentFile), true);
    if (!is_array($concurrentData)) {
        $concurrentData = ["requests" => 1, "start_time" => time()];
    } else {
        $concurrentData["requests"]++;
        file_put_contents($concurrentFile, json_encode($concurrentData));
    }

    if ($concurrentData["requests"] > 50 && !$skipVerifikasi) {
        banIpIptables($ip, "Concurrent requests exceeded: {$concurrentData['requests']}");
        http_response_code(429);
        die("🚫 Too many concurrent requests.");
    }

    if (time() - $concurrentData["start_time"] > 5) {
        $concurrentData = ["requests" => 1, "start_time" => time()];
        file_put_contents($concurrentFile, json_encode($concurrentData));
    }
}

if ($skipVerifikasi) {
    if (file_exists(__DIR__ . '/index.php.bak')) {
        require __DIR__ . '/index.php.bak';
    } else {
        echo "Panel is running normally.";
    }
    exit;
}

if (empty($ua)) {
    http_response_code(403);
    die("🚫 Empty User-Agent blocked.");
}

$badUaKeywords = [
    'curl', 'wget', 'python', 'scrapy', 'sqlmap', 'nikto', 'masscan',
    'zgrab', 'crawler', 'scanner', 'spider', 'bot', 'axios', 'okhttp',
    'libwww', 'perl', 'ruby', 'java/'
];

foreach ($badUaKeywords as $badUa) {
    if (stripos($ua, $badUa) !== false) {
        http_response_code(403);
        die("🚫 Bad User-Agent blocked.");
    }
}

$dailyLimitFile = sys_get_temp_dir() . "/daily_" . md5($ip);
$dailyLimit = 500;

if (!file_exists($dailyLimitFile)) {
    $dailyData = ["count" => 1, "day" => date('Y-m-d')];
    file_put_contents($dailyLimitFile, json_encode($dailyData));
} else {
    $dailyData = json_decode(file_get_contents($dailyLimitFile), true);
    if (!is_array($dailyData)) {
        $dailyData = ["count" => 0, "day" => date('Y-m-d')];
    }

    if ($dailyData["day"] !== date('Y-m-d')) {
        $dailyData = ["count" => 1, "day" => date('Y-m-d')];
    } else {
        $dailyData["count"]++;
    }

    file_put_contents($dailyLimitFile, json_encode($dailyData));
}

if ($dailyData["count"] > $dailyLimit) {
    banIpIptables($ip, "Daily limit exceeded: {$dailyData['count']} requests today");
    http_response_code(429);
    die("🚫 Daily request limit exceeded. Try again tomorrow.");
}

$dangerousMethods = ['OPTIONS', 'CONNECT', 'TRACE', 'TRACK'];

if (in_array($method, $dangerousMethods)) {
    banIpIptables($ip, "Dangerous method blocked: $method");
    http_response_code(405);
    die("🚫 Method {$method} is not allowed.");
}

function banIpIptables($ip, $reason) {
    $ipBanLogFile = __DIR__ . '/ip_ban.log';

    if (file_exists($ipBanLogFile)) {
        $banned = file($ipBanLogFile, FILE_IGNORE_NEW_LINES);
        foreach ($banned as $line) {
            if (strpos($line, "IP: $ip |") !== false) {
                return true;
            }
        }
    }

    exec("ipset create blacklist hash:ip timeout 86400 -exist 2>/dev/null");
    exec("ipset add blacklist $ip -exist 2>/dev/null");
    exec("iptables -I INPUT -m set --match-set blacklist src -j DROP 2>/dev/null");

    $logEntry = date('Y-m-d H:i:s') . " | IP: $ip | Reason: $reason\n";
    file_put_contents($ipBanLogFile, $logEntry, FILE_APPEND);

    return true;
}

$globalLockFile = sys_get_temp_dir() . "/global_lock";
$lockDuration = 300;

if (file_exists($globalLockFile)) {
    $lockTime = (int)file_get_contents($globalLockFile);
    if (time() - $lockTime < $lockDuration) {
        http_response_code(429);
        header('Retry-After: ' . ($lockDuration - (time() - $lockTime)));
        die("🚫 Too many requests. Please try again later.");
    } else {
        @unlink($globalLockFile);
    }
}

$rateFile = sys_get_temp_dir() . "/rate_" . md5($ip . $method);
$rateWindow = 60;
$maxRequests = 30;

if ($method === 'POST') {
    $maxRequests = 20;
} elseif ($method === 'PUT' || $method === 'DELETE') {
    $maxRequests = 60;
    $rateWindow = 120;
}

if (strpos($path, '/login') !== false || strpos($path, '/auth') !== false) {
    $maxRequests = 20;
    $rateWindow = 300;
}

if (file_exists($rateFile)) {
    $data = json_decode(file_get_contents($rateFile), true);
    if (!is_array($data)) {
        $data = ["count" => 0, "time" => time()];
    }
} else {
    $data = ["count" => 0, "time" => time()];
}

if ((time() - $data["time"]) > $rateWindow) {
    $data = ["count" => 0, "time" => time()];
}

$data["count"]++;
file_put_contents($rateFile, json_encode($data));

if ($data["count"] > $maxRequests) {
    banIpIptables($ip, "Rate limit exceeded: {$data['count']} requests in {$rateWindow} sec");
    file_put_contents($globalLockFile, time());
    http_response_code(403);
    die("🚫 Blocked");
}

if (file_exists(__DIR__ . '/index.php.bak')) {
    require __DIR__ . '/index.php.bak';
} else {
    echo "Panel is running normally.";
}
exit;
PHP_EOF

ipset create blacklist hash:ip timeout 86400 -exist 2>/dev/null
iptables -I INPUT -m set --match-set blacklist src -j DROP 2>/dev/null

echo -e "\033[1;45m        FIREWALL INSTALL DONE        \033[0m"
