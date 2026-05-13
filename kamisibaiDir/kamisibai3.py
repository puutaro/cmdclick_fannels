import os
import cv2
import argparse
import sys
import re
import math
import json
import time
from faster_whisper import WhisperModel

# --- エスケープシーケンス用設定 ---
MOVE_TOP = "\033[H"
CLEAR_LINE = "\033[K"

def format_text(text):
    if len(text) <= 10: return text
    return re.sub(r'([。、！？])', r'\1<br>', text)

def update_timer(start_time):
    """最上部に経過時間を固定表示する"""
    elapsed = time.time() - start_time
    sys.stdout.write(f"\033[s")
    sys.stdout.write(f"\033[1;1H")
    sys.stdout.write(f"\033[1;33m[ 累計経過時間: {elapsed:7.2f}s ]\033[0m")
    sys.stdout.write(f"\033[u")
    sys.stdout.flush()

def save_html_page(page_idx, total_pages, segments_chunk, output_folder, display_title):
    html_folder = os.path.join(output_folder, "html")
    if page_idx == 1:
        file_path = os.path.join(output_folder, "index.html")
        img_rel_path = "img/"
        data_js_path = "data.js"
        link_prefix = "html/"
        to_index_link = "index.html"
    else:
        file_path = os.path.join(html_folder, f"index_{page_idx}.html")
        img_rel_path = "../img/"
        data_js_path = "../data.js"
        link_prefix = ""
        to_index_link = "../index.html"

    def generate_nav(current, total):
        nav = '<div class="pagination">'
        win = 5 
        start = max(1, current - win)
        end = min(total, current + win)
        if start > 1:
            nav += f'<a href="{to_index_link}" class="page-link">1</a>'
            if start > 2: nav += '<span class="dots">..</span>'
        for i in range(start, end + 1):
            active = 'active' if i == current else ''
            target = to_index_link if i == 1 else f"{link_prefix}index_{i}.html"
            nav += f'<a href="{target}" class="page-link {active}">{i}</a>'
        if end < total:
            if end < total - 1: nav += '<span class="dots">..</span>'
            nav += f'<a href="{link_prefix}index_{total}.html" class="page-link">{total}</a>'
        nav += '</div>'
        return nav

    nav_html = generate_nav(page_idx, total_pages)

    html_content = f"""
    <!DOCTYPE html>
    <html lang="ja"><head><meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
    <title>{display_title} - P.{page_idx}</title>
    <style>
        body {{ font-family: 'Helvetica Neue', Arial, sans-serif; background: #f0f2f5; color: #1c1e21; margin: 0; padding-top: 80px; padding-bottom: 120px; overflow-x: hidden; }}
        #main-header {{ position: fixed; top: 0; left: 0; width: 100%; background: rgba(255, 255, 255, 0.98); border-bottom: 1px solid #ddd; z-index: 5000; box-shadow: 0 2px 10px rgba(0,0,0,0.08); display: flex; justify-content: center; align-items: center; padding: 15px 0; transition: transform 0.3s ease; }}
        #main-footer {{ position: fixed; bottom: 0; left: 0; width: 100%; background: rgba(255, 255, 255, 0.98); border-top: solid 1px #ddd; padding: 15px 0; z-index: 6000; display: flex; flex-direction: column; align-items: center; gap: 12px; transition: all 0.3s ease; }}
        
        .header-hidden {{ transform: translateY(-100%); }}
        .footer-hidden {{ transform: translateY(100%); }}
        .header-title {{ font-size: 1.2rem; font-weight: bold; color: #1c1e21; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; max-width: 90%; }}
        
        /* 検索ボックスの1.5倍スケール設定 */
        #search-box {{ display: flex; gap: 10px; width: 95%; max-width: 800px; transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1); z-index: 8001; }}
        #search-input {{ 
            flex: 1; 
            padding: 15px 25px; 
            font-size: 1.5rem; /* 1.5倍 */
            border: 3px solid #ddd; 
            border-radius: 40px; 
            outline: none; 
            background: #fff;
            -webkit-appearance: none;
        }}
        #search-btn {{ 
            padding: 12px 28px; 
            font-size: 1.2rem; 
            background: #0084ff; 
            color: white; 
            border: none; 
            border-radius: 40px; 
            cursor: pointer; 
            font-weight: bold; 
            box-shadow: 0 4px 12px rgba(0,132,255,0.2);
            -webkit-tap-highlight-color: transparent; 
        }}
        
        /* スマホ中央配置モード */
        @media (max-width: 768px) {{
            body.typing-mode #main-footer {{ 
                background: rgba(0, 0, 0, 0.85); 
                height: 100%; 
                top: 0; 
                justify-content: center; 
                border: none;
            }}
            body.typing-mode #search-box {{
                transform: translateY(-25%); /* キーボードの上 */
                flex-direction: column;
                align-items: center;
            }}
            body.typing-mode #search-input {{
                width: 90%;
                border-color: #0084ff;
                box-shadow: 0 0 25px rgba(0,132,255,0.4);
            }}
            body.typing-mode #search-btn {{
                width: 60%;
                height: 60px;
                font-size: 1.5rem;
            }}
            body.typing-mode .pagination {{ display: none !important; }}
        }}

        .container {{ max-width: 1000px; margin: auto; padding: 0 15px; }}
        .card {{ background: #fff; border: 1px solid #ddd; margin-bottom: 25px; display: flex; border-radius: 15px; overflow: hidden; scroll-margin-top: 100px; box-shadow: 0 2px 8px rgba(0,0,0,0.05); }}
        .card.highlight {{ border: 3px solid #0084ff; background: #e7f3ff; }}
        .img-box {{ flex: 0 0 45%; cursor: pointer; background: #000; display: flex; align-items: center; }}
        img.thumb {{ width: 100%; height: auto; display: block; }}
        .content {{ padding: 25px; flex: 1; }}
        .timestamp {{ color: #0084ff; font-size: 1.1rem; margin-bottom: 8px; font-weight: bold; font-family: monospace; }}
        .text {{ font-size: 1.6rem; line-height: 1.5; color: #050505; word-break: break-all; }}
        
        #search-overlay {{ position: fixed; top: 0; left: 0; width: 100%; height: 100%; background: rgba(0,0,0,0.5); z-index: 7000; display: none; justify-content: center; }}
        #search-dialog {{ background: #f0f2f5; width: 100%; max-width: 1000px; height: 100%; display: flex; flex-direction: column; box-shadow: 0 0 20px rgba(0,0,0,0.2); }}
        #search-results-container {{ flex: 1; overflow-y: auto; padding: 20px; }}
        
        #search-footer-internal {{ background: #fff; border-top: 1px solid #ddd; display: flex; flex-direction: column; align-items: center; padding: 15px 10px; gap: 15px; flex-shrink: 0; }}
        #search-res-count {{ font-weight: bold; color: #0084ff; font-size: 1rem; text-align: center; }}
        
        .pagination {{ display: flex; gap: 6px; flex-wrap: wrap; justify-content: center; align-items: center; }}
        .page-link {{ text-decoration: none; color: #333; padding: 8px 12px; border-radius: 8px; background: #fff; border: 1px solid #ddd; font-weight: bold; cursor: pointer; min-width: 35px; text-align: center; font-size: 0.9rem; }}
        .page-link.active {{ background: #0084ff; color: #fff; border-color: #0084ff; }}
        .dots {{ color: #999; padding: 0 4px; font-weight: bold; }}
        
        #overlay {{ position: fixed; top: 0; left: 0; width: 100%; height: 100%; background: rgba(0,0,0,0.95); display: none; align-items: center; justify-content: center; z-index: 9999; cursor: zoom-out; }}
        #overlay img {{ max-width: 100%; max-height: 100%; object-fit: contain; }}
        
        @media (max-width: 768px) {{ 
            body {{ padding-top: 70px; padding-bottom: 160px; }}
            .card {{ flex-direction: column; }} 
            .img-box {{ flex: 0 0 auto; width: 100%; }} 
            .text {{ font-size: 2.0rem; }}
        }}
    </style>
    <script src="{data_js_path}"></script>
    <script>
        let lastScrollY = 0;
        let isProcessingScroll = true;
        const pathPrefix = window.location.pathname.includes('/html/') ? "../" : "";
        
        window.addEventListener('DOMContentLoaded', () => {{
            const searchInput = document.getElementById('search-input');
            const container = document.querySelector('.container');
            const pagination = document.querySelector('.pagination');
            const header = document.getElementById('main-header');
            const footer = document.getElementById('main-footer');

            function enterSearchMode() {{
                if (window.innerWidth <= 768) {{
                    document.body.classList.add('typing-mode');
                    container.style.display = 'none';
                    header.style.display = 'none';
                }}
            }}

            function exitSearchMode() {{
                document.body.classList.remove('typing-mode');
                container.style.display = 'block';
                header.style.display = 'flex';
                window.scrollTo(0, lastScrollY);
            }}

            searchInput.addEventListener('focus', () => {{
                if (!history.state || !history.state.typing) {{
                    history.pushState({{typing: true}}, "");
                }}
                enterSearchMode();
            }});

            searchInput.addEventListener('blur', () => {{
                setTimeout(() => {{
                    if (document.getElementById('search-overlay').style.display !== 'flex') {{
                        exitSearchMode();
                    }}
                }}, 250);
            }});

            window.addEventListener('popstate', (e) => {{
                if (document.activeElement === searchInput) searchInput.blur();
                
                document.getElementById('search-overlay').style.display = 'none';
                document.getElementById('overlay').style.display = 'none';
                document.body.style.overflow = 'auto';
                
                searchInput.value = '';
                
                isProcessingScroll = true;
                header.classList.remove('header-hidden');
                footer.classList.remove('footer-hidden');

                if (e.state && e.state.typing) {{
                    enterSearchMode();
                }} else {{
                    exitSearchMode();
                }}
            }});

            window.addEventListener('keydown', (e) => {{
                if (e.key === 'Escape') {{
                    if (document.getElementById('overlay').style.display === 'flex' || 
                        document.getElementById('search-overlay').style.display === 'flex' || 
                        (document.activeElement === searchInput)) {{
                        history.back();
                    }}
                }}
            }});

            const hash = window.location.hash;
            if(hash) setTimeout(() => {{
                const el = document.querySelector(hash);
                if(el) {{ el.classList.add('highlight'); el.scrollIntoView({{behavior: 'smooth', block: 'center'}}); }}
            }}, 400);
        }});

        function doSearch() {{
            const input = document.getElementById('search-input');
            const q = input.value.trim();
            if(!q) return;
            if (history.state && history.state.typing) {{
                history.replaceState({{searchView: true}}, "");
            }} else if (!history.state || !history.state.searchView) {{
                history.pushState({{searchView: true}}, "");
            }}
            input.blur();
            renderSearch(q, 1);
        }}

        function renderSearch(query, page, fromPop = false) {{
            const overlay = document.getElementById('search-overlay');
            const container = document.getElementById('search-results-container');
            const resCount = document.getElementById('search-res-count');
            const paginationBox = document.getElementById('search-pagination-box');
            if (typeof allData === 'undefined') return;
            
            if (!fromPop && (!history.state || !history.state.searchView)) {{
                history.pushState({{searchView: true}}, "");
            }}

            const hits = allData.filter(d => d.text.toLowerCase().includes(query.toLowerCase()));
            const perPage = 15;
            const totalSearchPages = Math.ceil(hits.length / perPage);
            const startIdx = (page - 1) * perPage;
            const pagedHits = hits.slice(startIdx, startIdx + perPage);
            
            resCount.innerText = `「${{query}}」の検索結果: ${{hits.length}}件`;
            container.innerHTML = "";
            const regex = new RegExp(`(${{query}})`, 'gi');
            pagedHits.forEach(d => {{
                const hText = d.text.replace(regex, '<b style="color:#0084ff">$1</b>');
                const target = (d.page === 1 ? pathPrefix + "index.html" : pathPrefix + "html/index_" + d.page + ".html") + "#card-" + d.id;
                container.innerHTML += `<div class="card" style="cursor:pointer" onclick="closeSearchBeforeNav('${{target}}')"><div class="img-box"><img src="${{pathPrefix + d.img}}" class="thumb"></div><div class="content"><div class="timestamp">PAGE ${{d.page}} | ${{d.time}}</div><div class="text">${{hText}}</div></div></div>`;
            }});

            let sNav = '<div class="pagination">';
            if (totalSearchPages > 1) {{
                const win = 3; 
                const startP = Math.max(1, page - win);
                const endP = Math.min(totalSearchPages, page + win);
                
                if (startP > 1) {{
                    sNav += `<a onclick="renderSearch('${{query}}', 1, true)" class="page-link">1</a>`;
                    if (startP > 2) sNav += '<span class="dots">..</span>';
                }}
                for (let i = startP; i <= endP; i++) {{
                    const active = (i === page) ? 'active' : '';
                    sNav += `<a onclick="renderSearch('${{query}}', ${{i}}, true)" class="page-link ${{active}}">${{i}}</a>`;
                }}
                if (endP < totalSearchPages) {{
                    if (endP < totalSearchPages - 1) sNav += '<span class="dots">..</span>';
                    sNav += `<a onclick="renderSearch('${{query}}', ${{totalSearchPages}}, true)" class="page-link">${{totalSearchPages}}</a>`;
                }}
            }}
            sNav += '</div>';
            paginationBox.innerHTML = sNav;

            overlay.style.display = 'flex'; 
            document.body.style.overflow = 'hidden'; 
            container.scrollTop = 0;
        }}

        function closeSearchUI() {{ if(history.state?.searchView) history.back(); }}
        
        function closeSearchBeforeNav(target) {{
            document.getElementById('search-input').value = '';
            if(history.state?.searchView) history.back();
            setTimeout(() => {{ location.href = target; }}, 100);
        }}

        const handleScroll = () => {{
            if (!isProcessingScroll || document.body.classList.contains('typing-mode')) return;
            const header = document.getElementById('main-header'), footer = document.getElementById('main-footer');
            const curY = window.scrollY;
            const diff = curY - lastScrollY;
            if (curY > 50) {{
                if (diff > 5) {{ footer.classList.add('footer-hidden'); header.classList.remove('header-hidden'); }}
                else if (diff < -5) {{ header.classList.add('header-hidden'); footer.classList.remove('footer-hidden'); }}
            }} else {{ header.classList.remove('header-hidden'); footer.classList.remove('footer-hidden'); }}
            lastScrollY = curY;
        }};
        window.addEventListener('scroll', handleScroll, true);

        function openFull(src) {{ 
            document.getElementById('fullImg').src = src; 
            document.getElementById('overlay').style.display = 'flex'; 
            document.body.style.overflow = 'hidden'; 
            isProcessingScroll = false;
            history.pushState({{fullView: true}}, ""); 
        }}
        function closeFull() {{ if(history.state?.fullView) history.back(); }}
    </script>
    </head><body>
    <div id="overlay" onclick="closeFull()"><img id="fullImg" src=""></div>
    <div id="search-overlay" onclick="if(event.target===this) closeSearchUI()">
        <div id="search-dialog">
            <div id="search-results-container"></div>
            <div id="search-footer-internal">
                <div id="search-res-count"></div>
                <div id="search-pagination-box"></div>
            </div>
        </div>
    </div>
    <header id="main-header"><div class="header-title">{display_title}</div></header>
    <div class="container">
    """

    for i, s, full_fn in segments_chunk:
        fmt_text = format_text(s.text.strip())
        sm, ss = divmod(int(s.start), 60)
        em, es = divmod(int(s.end), 60)
        card_id = f"card-{i:04d}"
        html_content += f"""
        <div class="card" id="{card_id}">
            <div class="img-box" onclick="openFull('{img_rel_path}{full_fn}')"><img src="{img_rel_path}{full_fn}" class="thumb"></div>
            <div class="content">
                <div class="timestamp">{sm:02d}:{ss:02d} - {em:02d}:{es:02d}</div>
                <div class="text">{fmt_text}</div>
            </div>
        </div>"""
    
    html_content += f"""
    </div>
    <footer id="main-footer">
        <div id="search-box">
            <input type="text" id="search-input" placeholder="検索..." onkeypress="if(event.key==='Enter') doSearch()">
            <button id="search-btn" onclick="doSearch()" ontouchstart="doSearch()">検索</button>
        </div>
        {nav_html}
    </footer>
    </body></html>"""
    with open(file_path, "w", encoding="utf-8") as f: f.write(html_content)

def generate_storyboard(video_path, output_folder, prompt=None, lang="ja", model_size="base"):
    os.makedirs(os.path.join(output_folder, "img"), exist_ok=True)
    os.makedirs(os.path.join(output_folder, "html"), exist_ok=True)
    sys.stdout.write("\033[2J\033[H\n")
    start_total = time.time()

    print(f"[1/4] 音声解析中...")
    model = WhisperModel(model_size, device="cpu", compute_type="int8")
    segments_gen, info = model.transcribe(video_path, beam_size=5, initial_prompt=prompt, language=lang)
    all_segments = []
    for segment in segments_gen:
        all_segments.append(segment)
        update_timer(start_total)
        sys.stdout.write(f"\r      解析進捗: {segment.end:7.2f}s / {info.duration:7.2f}s")
        sys.stdout.flush()

    print(f"\n[2/4] 画像抽出中...")
    cap = cv2.VideoCapture(video_path)
    processed_data = []
    total_seg = len(all_segments)
    for i, s in enumerate(all_segments):
        update_timer(start_total)
        cap.set(cv2.CAP_PROP_POS_MSEC, s.start * 1000)
        ret, frame = cap.read()
        if ret:
            full_fn = f"full_{i:04d}.webp"
            cv2.imwrite(os.path.join(output_folder, "img", full_fn), frame, [int(cv2.IMWRITE_WEBP_QUALITY), 50])
            processed_data.append((i, s, full_fn))
        sys.stdout.write(f"\r      抽出進捗: {i+1:4} / {total_seg} 枚")
        sys.stdout.flush()
    cap.release()

    print(f"\n[3/4] 検索データ出力中...")
    search_list = []
    for i, s, full_fn in processed_data:
        search_list.append({"id": f"{i:04d}", "page": math.floor(s.start / 300) + 1, "time": f"{int(s.start//60):02d}:{int(s.start%60):02d}", "text": s.text.strip(), "img": f"img/{full_fn}"})
    with open(os.path.join(output_folder, "data.js"), "w", encoding="utf-8") as f:
        f.write("const allData = "); json.dump(search_list, f, ensure_ascii=False); f.write(";")

    print(f"[4/4] HTML出力中...")
    pages_data = []
    if processed_data:
        max_s = processed_data[-1][1].start
        total_p = math.ceil(max_s / 300) if max_s > 0 else 1
        for p in range(1, total_p + 1):
            chunk = [d for d in processed_data if (p-1)*300 <= d[1].start < p*300]
            if chunk: pages_data.append(chunk)
    
    title = os.path.basename(video_path)
    for idx, chunk in enumerate(pages_data):
        update_timer(start_total)
        save_html_page(idx + 1, len(pages_data), chunk, output_folder, title)
        sys.stdout.write(f"\r      出力進捗: {idx+1:4} / {len(pages_data)} ページ")
        sys.stdout.flush()

    print(f"\n\n[+] 処理終了！ 出力: {os.path.join(output_folder, 'index.html')}")

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--src', type=str, required=True)
    parser.add_argument('--out', type=str, required=True)
    parser.add_argument('--prompt', type=str, default=None)
    parser.add_argument('--lang', type=str, default="ja")
    parser.add_argument('--model', type=str, default="base")
    args = parser.parse_args()
    generate_storyboard(args.src, args.out, prompt=args.prompt, lang=args.lang, model_size=args.model)

if __name__ == "__main__":
    main()