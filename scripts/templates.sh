#!/bin/bash

apply_loading_v1() {
    cat > /var/www/html/index.html << 'EOF'
<!DOCTYPE html><html><head><meta charset="utf-8"><title>Loading</title><style>body{background:#0f172a;height:100vh;margin:0;display:flex;align-items:center;justify-content:center;font-family:sans-serif}.spinner{width:50px;height:50px;border:5px solid rgba(255,255,255,0.1);border-top:5px solid #38bdf8;border-radius:50%;animation:spin 1s linear infinite}@keyframes spin{0%{transform:rotate(0deg)}100%{transform:rotate(360deg)}}</style></head><body><div class="spinner"></div></body></html>
EOF
}

apply_loading_v2() {
    cat > /var/www/html/index.html << 'EOF'
<!DOCTYPE html><html><head><meta charset="utf-8"><title>Secure Gateway</title><style>body{background:#000;color:#0f0;font-family:monospace;height:100vh;margin:0;display:flex;flex-direction:column;align-items:center;justify-content:center}.t{font-size:20px;margin-bottom:20px;letter-spacing:2px}.dots::after{content:'';animation:dots 1.5s steps(4,end) infinite}@keyframes dots{0%,20%{content:''}40%{content:'.'}60%{content:'..'}80%,100%{content:'...'}}</style></head><body><div class="t">ESTABLISHING ENCRYPTED CONNECTION<span class="dots"></span></div><div style="font-size:12px;color:#050">REMOTE_ADDR: AUTHENTICATED</div></body></html>
EOF
}

apply_realestate() {
    cat > /var/www/html/index.html << 'EOF'
<!DOCTYPE html><html><head><meta charset="utf-8"><title>Elite Realty Group</title><style>body{font-family:'Segoe UI',sans-serif;margin:0;color:#333}header{background:#2c3e50;color:#fff;padding:20px;text-align:center}section{padding:50px;max-width:800px;margin:0 auto}h1{color:#2c3e50}.card{border:1px solid #ddd;padding:20px;margin-bottom:20px;border-radius:8px}</style></head><body><header><h1>Elite Realty Group</h1></header><section><h2>Featured Properties</h2><div class="card"><h3>Luxury Villa - Mediterranean Coast</h3><p>Price: $2,450,000</p></div><div class="card"><h3>Modern Penthouse - Downtown</h3><p>Price: $1,100,000</p></div></section></body></html>
EOF
}
