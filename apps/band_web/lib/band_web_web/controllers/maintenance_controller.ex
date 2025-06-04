defmodule BandWebWeb.MaintenanceController do
  use BandWebWeb, :controller

  @moduledoc """
  정비 중 페이지 컨트롤러
  
  사이트 점검이나 업데이트 시 사용자에게 안내 페이지를 보여줍니다.
  """

  def show(conn, _params) do
    conn
    |> put_status(503)
    |> put_resp_content_type("text/html")
    |> send_resp(503, maintenance_page())
  end

  defp maintenance_page do
    """
    <!DOCTYPE html>
    <html lang="ko">
    <head>
      <meta charset="utf-8">
      <meta name="viewport" content="width=device-width, initial-scale=1">
      <title>🧹 밴쓱싹 - 정비 중</title>
      <script src="https://cdn.tailwindcss.com"></script>
      <meta http-equiv="refresh" content="60">
      <style>
        @keyframes bounce-slow {
          0%, 100% { transform: translateY(0); }
          50% { transform: translateY(-10px); }
        }
        @keyframes spin-slow {
          from { transform: rotate(0deg); }
          to { transform: rotate(360deg); }
        }
        @keyframes pulse-glow {
          0%, 100% { box-shadow: 0 0 20px rgba(139, 92, 246, 0.3); }
          50% { box-shadow: 0 0 40px rgba(139, 92, 246, 0.6); }
        }
        .bounce-slow { animation: bounce-slow 2s infinite; }
        .spin-slow { animation: spin-slow 3s linear infinite; }
        .pulse-glow { animation: pulse-glow 2s infinite; }
      </style>
    </head>
    <body class="min-h-screen bg-gradient-to-br from-pink-50 via-purple-50 to-blue-50">
      <div class="min-h-screen flex items-center justify-center px-4">
        <div class="max-w-lg mx-auto text-center">
          <div class="mb-8">
            <div class="text-9xl bounce-slow">🧹</div>
            <div class="flex justify-center items-center gap-4 mt-6">
              <div class="text-3xl spin-slow">⚙️</div>
              <div class="text-3xl spin-slow" style="animation-delay: 0.5s;">🔧</div>
              <div class="text-3xl spin-slow" style="animation-delay: 1s;">⚡</div>
            </div>
          </div>
          
          <h1 class="text-5xl font-bold bg-gradient-to-r from-pink-500 via-purple-500 to-blue-500 bg-clip-text text-transparent mb-6">
            밴쓱싹 대청소 중
          </h1>
          
          <div class="bg-white/90 backdrop-blur-sm rounded-3xl p-8 shadow-2xl border border-purple-200 mb-8 pulse-glow">
            <div class="text-6xl mb-4">🏗️</div>
            
            <h2 class="text-2xl font-bold text-gray-800 mb-4">
              더 깔끔한 서비스 준비 중
            </h2>
            
            <p class="text-lg text-gray-700 mb-6">
              💝 더 나은 밴드 댓글 정리 경험을 위해<br>
              열심히 업그레이드하고 있어요!
            </p>
            
            <div class="bg-gradient-to-r from-blue-50 to-purple-50 border border-blue-200 rounded-2xl p-6 mb-6">
              <div class="text-blue-800 space-y-2">
                <div class="flex items-center justify-center">
                  <span class="mr-2">🚀</span>
                  <span class="font-bold">진행 중인 업데이트</span>
                  <span class="ml-2">✨</span>
                </div>
                <div class="text-sm">
                  • 더 빠른 댓글 삭제 속도<br>
                  • 향상된 사용자 인터페이스<br>
                  • 새로운 편의 기능 추가
                </div>
              </div>
            </div>
            
            <div class="bg-gradient-to-r from-green-50 to-emerald-50 border border-green-200 rounded-2xl p-4">
              <div class="flex items-center justify-center text-green-800">
                <span class="mr-2">⏰</span>
                <span class="text-sm">예상 완료 시간: 약 30분 내</span>
              </div>
            </div>
          </div>
          
          <div class="space-y-4">
            <button onclick="window.location.reload()" class="w-full bg-gradient-to-r from-pink-500 via-purple-500 to-blue-500 text-white px-8 py-4 rounded-2xl hover:from-pink-600 hover:via-purple-600 hover:to-blue-600 font-bold text-lg transform hover:scale-105 transition-all duration-300 shadow-lg">
              🔄 새로고침 (60초마다 자동)
            </button>
          </div>
          
          <div class="mt-8 text-sm text-gray-500 space-y-2">
            <p>💌 불편을 끼쳐드려 죄송합니다</p>
            <p>🎉 더 멋진 밴쓱싹으로 곧 돌아올게요!</p>
            <div id="timer" class="font-mono text-purple-600 mt-4"></div>
          </div>
        </div>
      </div>
      
      <script>
        // 60초 카운트다운
        let countdown = 60;
        const timer = document.getElementById('timer');
        
        function updateTimer() {
          timer.textContent = `⏱️ 자동 새로고침: ${countdown}초`;
          countdown--;
          
          if (countdown < 0) {
            countdown = 60;
            window.location.reload();
          }
        }
        
        updateTimer();
        setInterval(updateTimer, 1000);
      </script>
    </body>
    </html>
    """
  end
end