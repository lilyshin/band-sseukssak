defmodule BandWebWeb.ErrorHTML do
  @moduledoc """
  커스텀 에러 페이지 렌더링
  """
  use BandWebWeb, :html

  # 500 에러 (내부 서버 오류)
  def render("500.html", assigns) do
    ~H"""
    <!DOCTYPE html>
    <html lang="ko">
    <head>
      <meta charset="utf-8">
      <meta name="viewport" content="width=device-width, initial-scale=1">
      <title>🧹 밴쓱싹 - 작업 중</title>
      <script src="https://cdn.tailwindcss.com"></script>
      <style>
        @keyframes bounce-slow {
          0%, 100% { transform: translateY(0); }
          50% { transform: translateY(-10px); }
        }
        @keyframes spin-slow {
          from { transform: rotate(0deg); }
          to { transform: rotate(360deg); }
        }
        .bounce-slow { animation: bounce-slow 2s infinite; }
        .spin-slow { animation: spin-slow 3s linear infinite; }
      </style>
    </head>
    <body class="min-h-screen bg-gradient-to-br from-pink-50 via-purple-50 to-blue-50">
      <div class="min-h-screen flex items-center justify-center px-4">
        <div class="max-w-md mx-auto text-center">
          <div class="mb-8">
            <div class="text-8xl bounce-slow">🧹</div>
            <div class="text-2xl spin-slow inline-block mt-4">⚙️</div>
          </div>
          
          <h1 class="text-4xl font-bold bg-gradient-to-r from-pink-500 via-purple-500 to-blue-500 bg-clip-text text-transparent mb-4">
            밴쓱싹 정비 중
          </h1>
          
          <div class="bg-white/80 backdrop-blur-sm rounded-2xl p-6 shadow-xl border border-purple-100 mb-6">
            <p class="text-lg text-gray-700 mb-4">
              💝 더 깔끔한 서비스를 위해 열심히 청소하고 있어요!
            </p>
            <p class="text-sm text-purple-600 mb-4">
              ✨ 곧 다시 돌아올게요. 잠시만 기다려주세요! ✨
            </p>
            
            <div class="bg-gradient-to-r from-blue-50 to-purple-50 border border-blue-200 rounded-xl p-4">
              <div class="flex items-center justify-center text-sm text-blue-800">
                <span class="mr-2">🔧</span>
                <span>시스템 업그레이드 진행 중...</span>
                <span class="ml-2">💻</span>
              </div>
            </div>
          </div>
          
          <button onclick="window.location.reload()" class="bg-gradient-to-r from-pink-500 via-purple-500 to-blue-500 text-white px-6 py-3 rounded-2xl hover:from-pink-600 hover:via-purple-600 hover:to-blue-600 font-bold transform hover:scale-105 transition-all duration-200 shadow-lg">
            🔄 다시 시도하기
          </button>
          
          <p class="text-xs text-gray-500 mt-6">
            문제가 계속되면 잠시 후 다시 방문해주세요 💝
          </p>
        </div>
      </div>
    </body>
    </html>
    """
  end

  # 404 에러 (페이지 없음)
  def render("404.html", assigns) do
    ~H"""
    <!DOCTYPE html>
    <html lang="ko">
    <head>
      <meta charset="utf-8">
      <meta name="viewport" content="width=device-width, initial-scale=1">
      <title>🧹 밴쓱싹 - 페이지를 찾을 수 없어요</title>
      <script src="https://cdn.tailwindcss.com"></script>
      <style>
        @keyframes bounce-slow {
          0%, 100% { transform: translateY(0); }
          50% { transform: translateY(-10px); }
        }
        @keyframes float {
          0%, 100% { transform: translateY(0) rotate(-5deg); }
          50% { transform: translateY(-15px) rotate(5deg); }
        }
        .bounce-slow { animation: bounce-slow 2s infinite; }
        .float { animation: float 3s ease-in-out infinite; }
      </style>
    </head>
    <body class="min-h-screen bg-gradient-to-br from-pink-50 via-purple-50 to-blue-50">
      <div class="min-h-screen flex items-center justify-center px-4">
        <div class="max-w-md mx-auto text-center">
          <div class="mb-8">
            <div class="text-8xl bounce-slow">🧹</div>
            <div class="text-4xl float inline-block mt-4">🔍</div>
          </div>
          
          <h1 class="text-4xl font-bold bg-gradient-to-r from-pink-500 via-purple-500 to-blue-500 bg-clip-text text-transparent mb-4">
            어? 여기 없네요!
          </h1>
          
          <div class="bg-white/80 backdrop-blur-sm rounded-2xl p-6 shadow-xl border border-purple-100 mb-6">
            <p class="text-lg text-gray-700 mb-4">
              😅 찾으시는 페이지를 쓸어버린 것 같아요!
            </p>
            <p class="text-sm text-purple-600 mb-4">
              🏠 홈으로 돌아가서 다시 시작해볼까요?
            </p>
            
            <div class="bg-gradient-to-r from-orange-50 to-yellow-50 border border-orange-200 rounded-xl p-4">
              <div class="flex items-center justify-center text-sm text-orange-800">
                <span class="mr-2">💡</span>
                <span>올바른 주소인지 다시 한번 확인해주세요!</span>
              </div>
            </div>
          </div>
          
          <div class="space-y-3">
            <button onclick="window.location.href='/'" class="w-full bg-gradient-to-r from-pink-500 via-purple-500 to-blue-500 text-white px-6 py-3 rounded-2xl hover:from-pink-600 hover:via-purple-600 hover:to-blue-600 font-bold transform hover:scale-105 transition-all duration-200 shadow-lg">
              🏠 홈으로 돌아가기
            </button>
            
            <button onclick="window.history.back()" class="w-full bg-gradient-to-r from-gray-400 to-gray-500 text-white px-6 py-3 rounded-2xl hover:from-gray-500 hover:to-gray-600 font-bold transform hover:scale-105 transition-all duration-200 shadow-lg">
              ⬅️ 이전 페이지로
            </button>
          </div>
          
          <p class="text-xs text-gray-500 mt-6">
            Error 404 - Page Not Found 💔
          </p>
        </div>
      </div>
    </body>
    </html>
    """
  end

  # 기타 에러들
  def render(template, assigns) do
    assigns = assign(assigns, :template, template)
    ~H"""
    <!DOCTYPE html>
    <html lang="ko">
    <head>
      <meta charset="utf-8">
      <meta name="viewport" content="width=device-width, initial-scale=1">
      <title>🧹 밴쓱싹 - 문제가 발생했어요</title>
      <script src="https://cdn.tailwindcss.com"></script>
      <style>
        @keyframes bounce-slow {
          0%, 100% { transform: translateY(0); }
          50% { transform: translateY(-10px); }
        }
        .bounce-slow { animation: bounce-slow 2s infinite; }
      </style>
    </head>
    <body class="min-h-screen bg-gradient-to-br from-pink-50 via-purple-50 to-blue-50">
      <div class="min-h-screen flex items-center justify-center px-4">
        <div class="max-w-md mx-auto text-center">
          <div class="mb-8">
            <div class="text-8xl bounce-slow">🧹</div>
            <div class="text-4xl">😵</div>
          </div>
          
          <h1 class="text-4xl font-bold bg-gradient-to-r from-pink-500 via-purple-500 to-blue-500 bg-clip-text text-transparent mb-4">
            앗! 문제가 생겼어요
          </h1>
          
          <div class="bg-white/80 backdrop-blur-sm rounded-2xl p-6 shadow-xl border border-purple-100 mb-6">
            <p class="text-lg text-gray-700 mb-4">
              💫 예상치 못한 문제가 발생했어요!
            </p>
            <p class="text-sm text-purple-600 mb-4">
              🔧 빠르게 해결하고 있으니 잠시만 기다려주세요!
            </p>
            
            <div class="bg-gradient-to-r from-red-50 to-pink-50 border border-red-200 rounded-xl p-4">
              <div class="flex items-center justify-center text-sm text-red-800">
                <span class="mr-2">⚠️</span>
                <span>Error: <%= @template %></span>
              </div>
            </div>
          </div>
          
          <div class="space-y-3">
            <button onclick="window.location.reload()" class="w-full bg-gradient-to-r from-pink-500 via-purple-500 to-blue-500 text-white px-6 py-3 rounded-2xl hover:from-pink-600 hover:via-purple-600 hover:to-blue-600 font-bold transform hover:scale-105 transition-all duration-200 shadow-lg">
              🔄 다시 시도하기
            </button>
            
            <button onclick="window.location.href='/'" class="w-full bg-gradient-to-r from-gray-400 to-gray-500 text-white px-6 py-3 rounded-2xl hover:from-gray-500 hover:to-gray-600 font-bold transform hover:scale-105 transition-all duration-200 shadow-lg">
              🏠 홈으로 돌아가기
            </button>
          </div>
          
          <p class="text-xs text-gray-500 mt-6">
            문제가 계속되면 새로고침을 해보세요 💝
          </p>
        </div>
      </div>
    </body>
    </html>
    """
  end
end