---@meta

--- GraphicEngine (g) 시스템
---@class GraphicEngine
g = {}

--- 리소스 관리 (res) 시스템
---@class ResourceHub
res = {}

--- 입력 상태 (is) 시스템
---@class InputSystem
is = {}

--- 윈도우/시스템 제어 (sys) 시스템
---@class WindowSys
sys = {}

-----------------------------------------------------------
-- 루아에서 구현해야 하는 콜백 함수들 (Engine -> Lua)
-----------------------------------------------------------

--- 게임/앱 초기화 시 호출됩니다.
function Init() end

--- 매 프레임 업데이트 시 호출됩니다.
---@param dtMs number 이전 프레임으로부터 경과된 시간 (밀리초)
function Update(dtMs) end

--- 그리기 명령을 수행할 때 호출됩니다.
function Draw() end

--- 특정 좌표가 클릭 가능한 영역인지 확인합니다. (마우스 투과 제어용)
---@param x number 마우스 X 좌표 (Client 기준)
---@param y number 마우스 Y 좌표 (Client 기준)
---@return boolean hit true면 클릭 가능, false면 마우스 클릭이 창을 통과함
function CheckHit(x, y) end

--- 키보드 키가 눌렸을 때 호출됩니다.
---@param keyCode integer Windows Virtual-Key Code (예: 0x41 = 'A')
function OnKeyDown(keyCode) end

--- 키보드 키가 떼졌을 때 호출됩니다.
---@param keyCode integer Windows Virtual-Key Code
function OnKeyUp(keyCode) end

--- 마우스가 이동할 때 호출됩니다. (Raw Input)
---@param id integer 마우스 장치 고유 ID
---@param dx number X축 변화량
---@param dy number Y축 변화량
function OnMouseMove(id, dx, dy) end

--- 마우스 버튼이 눌렸을 때 호출됩니다.
---@param button integer 0: 왼쪽, 1: 오른쪽
---@param id integer 마우스 장치 고유 ID
function OnMouseDown(button, id) end

--- 마우스 버튼이 떼졌을 때 호출됩니다.
---@param button integer 0: 왼쪽, 1: 오른쪽
---@param id integer 마우스 장치 고유 ID
function OnMouseUp(button, id) end

--- 마우스 휠이 회전할 때 호출됩니다.
---@param delta integer 휠 회전량 (보통 120의 배수)
---@param id integer 마우스 장치 고유 ID
---@param dx number X축 변화량
---@param dy number Y축 변화량
function OnMouseWheel(delta, id, dx, dy) end

--- 윈도우가 비활성화(포커스 잃음)되었을 때 호출됩니다.
function OnInactive() end

--- 윈도우가 활성화(포커스 얻음)되었을 때 호출됩니다.
function OnActive() end

-----------------------------------------------------------
-- g
-----------------------------------------------------------

---@class Canvas
---g.offscreen()으로 생성된 오프스크린 렌더 타겟 객체입니다.
local Canvas = {}

---@meta

-- 1. 객체 지향 방식으로 호출되는 'Canvas' 타입 (usertype)
---@class Canvas
local Canvas = {}
function Canvas:batchBegin() end
function Canvas:batchEnd() end
function Canvas:rect(x, y, w, h, fill) end
function Canvas:circle(x, y, r, fill) end
function Canvas:polyline(vertices, closed) end
function Canvas:polygon(vertices) end
function Canvas:text(fontId, str, x, y) end
function Canvas:image(id, dx, dy, dw, dh, sx, sy, sw, sh, alpha) end
function Canvas:color(arg1, arg2, arg3, arg4) end
function Canvas:lineWidth(width) end
function Canvas:push() end
function Canvas:pop() end
function Canvas:translate(x, y) end
function Canvas:scale(sx, sy, ox, oy) end

-- 2. 정적 테이블로 호출되는 'g' 시스템 (함수 바인딩)
---@class GraphicSystem
g = {}

---@param x number
---@param y number
---@param w number
---@param h number
---@param fill? boolean
function g.rect(x, y, w, h, fill) end

---@param x number
---@param y number
---@param r number
---@param fill? boolean
function g.circle(x, y, r, fill) end

---@param vertices number[] {x1, y1, x2, y2, ...}
---@param closed? boolean
function g.polyline(vertices, closed) end

---@param vertices number[] {x1, y1, x2, y2, ...}
function g.polygon(vertices) end

---@param fontId integer
---@param str string
---@param x number
---@param y number
function g.text(fontId, str, x, y) end

---@param id integer
---@param dx number
---@param dy number
---@param dw? number
---@param dh? number
---@param sx? number
---@param sy? number
---@param sw? number
---@param sh? number
---@param alpha? number
function g.image(id, dx, dy, dw, dh, sx, sy, sw, sh, alpha) end

---@param w number
---@param h number
---@return Canvas
function g.offscreen(w, h) end

---@param source Canvas
---@param x number
---@param y number
---@param w? number
---@param h? number
---@param sx? number
---@param sy? number
---@param sw? number
---@param sh? number
---@param alpha? number
function g.draw(source, x, y, w, h, sx, sy, sw, sh, alpha) end

---@param arg1 string|number Hex 혹은 Red
---@param arg2? number Green 혹은 Alpha
---@param arg3? number Blue
---@param arg4? number Alpha
function g.color(arg1, arg2, arg3, arg4) end

---@param width number
function g.lineWidth(width) end

function g.push() end
function g.pop() end

---@param x number
---@param y number
function g.translate(x, y) end

---@param sx number
---@param sy number
---@param ox? number
---@param oy? number
function g.scale(sx, sy, ox, oy) end

---@param x number
---@param y number
---@param w number
---@param h number
function g.clip(x, y, w, h) end

---@meta

-----------------------------------------------------------
-- 입력 상태 시스템 (is) - BindToLuaInput
-----------------------------------------------------------

---@class InputSystem
is = {}

---특정 키가 현재 눌려 있는지 확인합니다.
---@param vkey integer Windows Virtual-Key Code (예: 0x41 = 'A')
---@return boolean isDown 눌려 있으면 true
function is.key(vkey) end

---현재 마우스의 상태 정보를 가져옵니다.
---@return integer x 마우스 클라이언트 X 좌표
---@return integer y 마우스 클라이언트 Y 좌표
---@return boolean left 왼쪽 버튼 클릭 여부
---@return boolean right 오른쪽 버튼 클릭 여부
function is.mouse() end

---현재 윈도우의 화면 좌표를 가져옵니다.
---@return integer x 윈도우 왼쪽 좌표
---@return integer y 윈도우 위쪽 좌표
function is.pos() end

---현재 윈도우의 크기를 가져옵니다.
---@return integer width 너비
---@return integer height 높이
function is.size() end

---작업 영역(태스크바 제외)의 크기를 가져옵니다.
---@return integer width 작업 영역 너비
---@return integer height 작업 영역 높이
function is.workArea() end

---전체 모니터 스크린의 해상도를 가져옵니다.
---@return integer width 스크린 너비
---@return integer height 스크린 높이
function is.screenSize() end

---@class MonitorInfo
---@field x integer 모니터 시작 X
---@field y integer 모니터 시작 Y
---@field w integer 모니터 너비
---@field h integer 모니터 높이
---@field workX integer 작업 영역 시작 X
---@field workY integer 작업 영역 시작 Y
---@field workW integer 작업 영역 너비
---@field workH integer 작업 영역 높이

---연결된 모든 모니터의 상세 정보 목록을 가져옵니다.
---@return MonitorInfo[] monitorList
function is.monitors() end

---현재 설정된 FPS 제한 값과 VSync 활성화 여부를 가져옵니다.
---@return integer fps 설정된 목표 FPS
---@return boolean vSync VSync 활성 여부
function is.fpsMode() end

---현재 창이 포커스(Foreground) 상태인지 확인합니다.
---@return boolean isFocused
function is.focus() end


-----------------------------------------------------------
-- 시스템 제어 모듈 (sys) - BindToLuaSys
-----------------------------------------------------------

---@class WindowSys
sys = {}

---윈도우의 크기를 변경합니다.
---@param w integer 너비
---@param h integer 높이
function sys.size(w, h) end

---윈도우의 위치를 변경합니다.
---@param x integer X 좌표
---@param y integer Y 좌표
function sys.pos(x, y) end

---마우스 커서를 보이거나 숨깁니다.
---@param show boolean true면 보임, false면 숨김
function sys.showCursor(show) end

---마우스 커서의 모양을 변경합니다.
---@param type? integer 시스템 커서 ID (기본값: 32512 - IDC_ARROW)
function sys.cursor(type) end

---마우스 커서의 이동 범위를 현재 윈도우 내부로 제한하거나 해제합니다.
---@param clip boolean true면 가두기, false면 해제
function sys.clip(clip) end

---윈도우를 항상 위(Topmost) 상태로 만들거나 해제합니다.
---@param topmost boolean true면 항상 위
function sys.topmost(topmost) end

---기본 브라우저를 통해 특정 URL을 엽니다.
---@param url string 열고자 하는 웹 주소
function sys.openURL(url) end

---애플리케이션을 종료합니다.
function sys.quit() end

-----------------------------------------------------------
-- 리소스 관리 시스템 (res) - BindLua
-----------------------------------------------------------

---@class ResourceHub
res = {}

---이미지 파일을 로드하고 고유 ID를 반환합니다.
---이미 로드된 파일은 캐시된 ID를 반환합니다.
---@param path string 이미지 파일 경로 (예: "assets/image.png")
---@return integer id 리소스 ID (로드 실패 시 -1)
function res.image(path) end

---시스템에 설치된 폰트를 로드하고 고유 ID를 반환합니다.
---@param name string 폰트 패밀리 이름 (예: "맑은 고딕", "Arial")
---@param size number 폰트 크기
---@param weight? integer 폰트 굵기 (기본값: 400 - Normal)
---@return integer id 리소스 ID (로드 실패 시 -1)
function res.font(name, size, weight) end

---폰트 파일(.ttf, .otf)을 직접 로드하고 고유 ID를 반환합니다.
---@param path string 폰트 파일 경로 (예: "fonts/myfont.ttf")
---@param family string 폰트 패밀리 이름 (파일 내부에 정의된 이름)
---@param size number 폰트 크기
---@return integer id 리소스 ID (로드 실패 시 -1)
function res.fontFile(path, family, size) end

---사운드 파일(.wav 등)을 로드하고 고유 ID를 반환합니다.
---@param path string 사운드 파일 경로
---@return integer id 리소스 ID (로드 실패 시 -1)
function res.sound(path) end

---@meta

-----------------------------------------------------------
-- 사운드 시스템 (snd)
-----------------------------------------------------------

---@class SoundSystem
snd = {}

---사운드를 한 번 재생합니다.
---@param soundId integer res.sound()로 로드한 ID
---@param volume? number 볼륨 (0.0 ~ 1.0)
---@param pan? number 팬 (-1.0:왼쪽, 1.0:오른쪽)
---@return integer handle 재생 중인 사운드의 고유 핸들
function snd.play(soundId, volume, pan) end

---사운드를 반복 재생합니다.
---@param soundId integer res.sound()로 로드한 ID
---@param volume? number 볼륨
---@return integer handle 재생 중인 사운드의 고유 핸들
function snd.loop(soundId, volume) end

---재생 중인 사운드를 정지합니다. 핸들이 없으면 전체를 정지합니다.
---@param handle? integer snd.play나 snd.loop에서 받은 핸들
function snd.stop(handle) end

---특정 사운드의 볼륨을 실시간으로 변경합니다.
---@param handle integer
---@param vol number (0.0 ~ 1.0)
function snd.volume(handle, vol) end

---사운드를 일시정지하거나 재개합니다.
---@param handle integer
---@param paused boolean true면 정지, false면 재개
function snd.pause(handle, paused) end

---전체 시스템의 마스터 볼륨을 설정합니다.
---@param vol number (0.0 ~ 1.0)
function snd.masterVolume(vol) end