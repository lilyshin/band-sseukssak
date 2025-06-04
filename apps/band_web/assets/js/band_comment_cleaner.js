// 환경 체크 및 프로덕션 모드 설정
(function() {
  window.isDevelopment = window.location.hostname === 'localhost' || window.location.hostname === '127.0.0.1';
  
  if (!window.isDevelopment) {
    const noop = function() {};
    ['log', 'debug', 'info', 'warn', 'error', 'assert', 'dir', 'dirxml', 'group', 'groupEnd', 'time', 'timeEnd', 'count', 'trace', 'profile', 'profileEnd'].forEach(function(method) {
      console[method] = noop;
    });
    
    // 전역 에러 핸들링
    window.onerror = function() { return true; };
    window.onunhandledrejection = function() { return true; };
  }
})();

class BandCommentCleaner {
  constructor() {
    this.apiBaseUrl = '/api';
    this.authData = this.loadAuthData();
    this.lastFailedComments = null;
    this.init();
    
    window.bandCommentCleaner = this;
  }

  init() {
    this.createUI();
    this.bindEvents();
    
    // 이미 인증된 사용자라면 UI 업데이트 및 밴드 로드
    if (this.authData) {
      this.updateAuthUI();
      this.loadBands();
    }
  }

  createUI() {
    const appHtml = `
      <div id="band-comment-cleaner" class="min-h-screen bg-gradient-to-br from-pink-50 via-purple-50 to-blue-50 py-6">
        <div class="max-w-2xl mx-auto px-4">
          <div class="text-center mb-8">
            <div class="text-6xl mb-4 animate-bounce">🧹</div>
            <h1 class="text-4xl font-bold bg-gradient-to-r from-pink-500 via-purple-500 to-blue-500 bg-clip-text text-transparent mb-2">
              밴쓱싹
            </h1>
            <p class="text-gray-600 text-sm">💫 한번에 깔끔하게! 귀찮은 댓글들을 모두 쓸어 버리세요! 💫</p>
          </div>
          
          ${this.getOAuthModeHTML()}
          
          <!-- 밴드 선택 섹션 -->
          <div id="band-section" class="bg-white/80 backdrop-blur-sm shadow-xl rounded-2xl p-6 mb-6 opacity-50 border border-blue-100">
            <div class="flex items-center gap-3 mb-4">
              <h2 class="text-xl font-bold text-gray-800">2. 밴드 선택</h2>
            </div>
            <div id="band-list" class="space-y-2">
              <div class="text-center py-8">
                <span class="text-4xl mb-2 block">😴</span>
                <p class="text-gray-500">먼저 계정 인증을 완료해 주세요~</p>
              </div>
            </div>
          </div>

          <!-- 삭제 실행 섹션 -->
          <div id="delete-section" class="bg-white/80 backdrop-blur-sm shadow-xl rounded-2xl p-6 opacity-50 border border-red-100">
            <div class="flex items-center gap-3 mb-4">
              <h2 class="text-xl font-bold text-gray-800">3. 쓸어 내기 실행</h2>
            </div>
            
            <!-- 삭제 타입 선택 -->
            <div class="mb-6">
              <div class="space-y-3">
                <label class="flex items-center p-3 border-2 border-purple-200 rounded-xl hover:border-purple-400 cursor-pointer bg-gradient-to-r from-purple-50 to-pink-50">
                  <input type="radio" name="delete-type" value="all-comments" class="mr-3 w-4 h-4 text-purple-600" checked>
                  <div class="flex-1">
                    <span class="font-bold text-purple-800">모든 댓글 쓸어 내기</span>
                    <p class="text-sm text-purple-600">선택한 밴드의 모든 댓글을 삭제합니다</p>
                  </div>
                </label>
                
                <label class="flex items-center p-3 border-2 border-orange-200 rounded-xl hover:border-orange-400 cursor-pointer bg-gradient-to-r from-orange-50 to-yellow-50">
                  <input type="radio" name="delete-type" value="keyword-comments" class="mr-3 w-4 h-4 text-orange-600">
                  <div class="flex-1">
                    <span class="font-bold text-orange-800">키워드 댓글만 쓸어 내기</span>
                    <p class="text-sm text-orange-600">특정 단어가 포함된 댓글만 삭제합니다</p>
                  </div>
                </label>
                
                <label class="flex items-center p-3 border-2 border-red-200 rounded-xl hover:border-red-400 cursor-pointer bg-gradient-to-r from-red-50 to-pink-50">
                  <input type="radio" name="delete-type" value="all-posts" class="mr-3 w-4 h-4 text-red-600">
                  <div class="flex-1">
                    <span class="font-bold text-red-800">모든 게시글 쓸어 내기</span>
                    <p class="text-sm text-red-600">선택한 밴드의 모든 게시글을 삭제합니다 (댓글도 함께 삭제됨)</p>
                  </div>
                </label>
              </div>
            </div>
            
            <!-- 키워드 입력 (조건부 표시) -->
            <div id="keyword-input" class="hidden mb-6">
              <h3 class="text-lg font-bold text-gray-700 mb-3 flex items-center gap-2">
                <span>🔍</span> 삭제할 키워드 입력
              </h3>
              <input type="text" id="keyword-text" placeholder="삭제할 댓글에 포함된 단어를 입력하세요" class="w-full p-3 border-2 border-orange-200 rounded-xl focus:border-orange-400 focus:outline-none text-gray-800">
              <p class="text-sm text-orange-600 mt-2">💡 대소문자 구분 없이 검색됩니다</p>
            </div>
            
            <div class="bg-gradient-to-r from-red-50 to-pink-50 border border-red-200 rounded-xl p-4 mb-4">
              <div class="flex">
                <div class="flex-shrink-0">
                  <span class="text-2xl">⚠️</span>
                </div>
                <div class="ml-3">
                  <p class="text-sm text-red-700">
                    <strong>🚨 주의해 주세요!</strong> 선택한 타입에 따라 댓글 또는 게시글이 영구적으로 쓸어집니다. 
                    <br>이 작업은 되돌릴 수 없어요! 💔
                  </p>
                </div>
              </div>
            </div>
            <button id="delete-btn" class="w-full bg-gradient-to-r from-red-500 to-pink-500 text-white py-4 px-6 rounded-2xl hover:from-red-600 hover:to-pink-600 focus:outline-none focus:ring-4 focus:ring-red-300 font-bold text-lg transform hover:scale-105 transition-all duration-200 shadow-lg disabled:opacity-50 disabled:transform-none" disabled>
              🧹 선택한 밴드의 모든 댓글 쓸어 버리기 ✨
            </button>
            <div id="delete-progress" class="hidden mt-4">
              <div class="bg-gradient-to-r from-blue-50 to-purple-50 border border-blue-200 rounded-xl p-4">
                <div class="flex items-center justify-center">
                  <div class="animate-spin rounded-full h-6 w-6 border-b-2 border-purple-600 mr-3"></div>
                  <span class="text-2xl mr-2">🚀</span>
                  <p class="text-blue-800 font-bold">쓸어 내는 중... 잠시만 기다려 주세요!</p>
                  <p class="text-sm text-gray-600 mt-2">💡 쿨 타임 제한으로 인해 시간이 다소 걸릴 수 있습니다</p>
                  <span class="text-2xl ml-2">✨</span>
                </div>
              </div>
            </div>
            <div id="delete-result" class="hidden mt-4"></div>
          </div>
        </div>
      </div>
    `;

    document.body.innerHTML = appHtml;
  }


  getOAuthModeHTML() {
    return `
      <!-- 인증 섹션 -->
      <div id="auth-section" class="bg-white/80 backdrop-blur-sm shadow-xl rounded-2xl p-6 mb-6 border border-purple-100">
        <div class="flex items-center justify-between mb-4">
          <div class="flex items-center gap-3">
            <h2 class="text-xl font-bold text-gray-800">1. 밴드 계정 인증</h2>
          </div>
          <button id="logout-btn" class="hidden bg-gray-100 hover:bg-gray-200 text-gray-700 px-4 py-2 rounded-xl text-sm font-medium transition-colors border border-gray-300">
            🚪 로그아웃
          </button>
        </div>
        
        <!-- 안내 메시지 -->
        <div class="mb-6 text-left">
          <p class="text-purple-600 text-sm">👇 아래 버튼을 클릭해 주세요!</p>
        </div>

        <div id="auth-form">
          <button id="auth-btn" class="w-full bg-gradient-to-r from-pink-500 via-purple-500 to-blue-500 text-white py-4 px-6 rounded-2xl hover:from-pink-600 hover:via-purple-600 hover:to-blue-600 focus:outline-none focus:ring-4 focus:ring-purple-300 font-bold text-lg transform hover:scale-105 transition-all duration-200 shadow-lg">
            🌈 밴드 계정으로 로그인하기 ✨
          </button>
          <p class="mt-4 text-center text-sm text-gray-500 flex items-center justify-center gap-1">
            <span>🔒</span>
            밴드 공식 OAuth로 안전하게 로그인돼요!
            <span>💖</span>
          </p>
        </div>
        
        <div id="auth-success" class="hidden">
          <div class="flex items-center justify-center bg-green-50 border border-green-200 rounded-xl p-4 mb-4">
            <span class="text-2xl mr-2">🎊</span>
            <span class="text-green-800 font-bold">로그인 완료!</span>
            <span class="text-2xl ml-2">🎉</span>
          </div>
        </div>
      </div>
    `;

    document.body.innerHTML = appHtml;
  }

  bindEvents() {
    // 공통 요소들
    document.getElementById('delete-btn').addEventListener('click', () => this.handleDelete());
    document.getElementById('auth-btn').addEventListener('click', () => this.handleAuth());
    
    // 삭제 타입 선택 이벤트 (나중에 UI 업데이트시 활성화)
    setTimeout(() => {
      const deleteTypeRadios = document.querySelectorAll('input[name="delete-type"]');
      if (deleteTypeRadios.length > 0) {
        deleteTypeRadios.forEach(radio => {
          radio.addEventListener('change', () => this.handleDeleteTypeChange());
        });
      }
    }, 100);
    
    // URL에서 오류 파라미터 확인
    const urlParams = new URLSearchParams(window.location.search);
    const error = urlParams.get('error');
    
    if (error) {
      alert('인증 중 오류가 발생했습니다: ' + decodeURIComponent(error));
      // URL에서 error 파라미터 제거
      window.history.replaceState({}, document.title, window.location.pathname);
    }
  }

  async handleAuth() {
    try {
      // 서버에 설정된 OAuth 앱 사용 (파라미터 불필요)
      const response = await fetch(`${this.apiBaseUrl}/auth/band`);
      const data = await response.json();

      if (data.success) {
        // 인증 페이지로 리다이렉트
        window.location.href = data.auth_url;
      } else {
        alert('인증 URL 생성 실패: ' + data.error);
      }
    } catch (error) {
      alert('인증 요청 실패: ' + error.message);
    }
  }

  async handleAuthCallback(code) {
    try {
      // 서버 OAuth 앱을 사용하므로 code만 전송
      const response = await fetch(`${this.apiBaseUrl}/auth/band/callback`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          code: code
        })
      });

      const data = await response.json();

      if (data.success) {
        this.authData = data.data;
        this.saveAuthData(this.authData);
        await this.updateAuthUI();
        await this.loadBands();
        
        // URL에서 code 파라미터 제거
        window.history.replaceState({}, document.title, window.location.pathname);
      } else {
        alert('토큰 발급 실패: ' + JSON.stringify(data.error));
      }
    } catch (error) {
      alert('콜백 처리 실패: ' + error.message);
    }
  }

  async updateAuthUI() {
    if (this.authData) {
      document.getElementById('auth-form').classList.add('hidden');
      document.getElementById('auth-success').classList.remove('hidden');
      
      // 로그아웃 버튼 표시
      const logoutBtn = document.getElementById('logout-btn');
      if (logoutBtn) {
        logoutBtn.classList.remove('hidden');
        logoutBtn.addEventListener('click', () => this.handleLogout());
      }
      
      // 밴드 섹션 활성화
      document.getElementById('band-section').classList.remove('opacity-50');
    }
  }

  async loadBands() {
    if (!this.authData) return;

    try {
      const response = await fetch(`${this.apiBaseUrl}/bands?access_token=${this.authData.access_token}`);
      
      // 응답이 JSON인지 확인
      const contentType = response.headers.get("content-type");
      if (!contentType || !contentType.includes("application/json")) {
        // HTML 에러 페이지가 온 경우
        await response.text(); // 응답 소비
        this.showBandLoadError(`서버 오류가 발생했습니다 (${response.status}). 잠시 후 다시 시도해 주세요.`);
        return;
      }

      const data = await response.json();

      if (data.success) {
        const bands = data.data.result_data.bands;
        this.renderBands(bands);
      } else {
        this.showBandLoadError('Failed to load bands. Please try again.');
      }
    } catch (error) {
      this.showBandLoadError('Network error occurred. Please try again.');
    }
  }

  showBandLoadError(message) {
    const bandList = document.getElementById('band-list');
    bandList.innerHTML = `
      <div class="text-center py-8">
        <span class="text-6xl mb-4 block">😭</span>
        <p class="text-gray-600 mb-4">${message}</p>
        <button onclick="location.reload()" class="px-6 py-3 bg-gradient-to-r from-blue-500 to-purple-500 text-white rounded-xl hover:from-blue-600 hover:to-purple-600 font-bold transform hover:scale-105 transition-all duration-200">
          🔄 다시 시도하기
        </button>
      </div>
    `;
  }

  renderBands(bands) {
    const bandList = document.getElementById('band-list');
    bandList.innerHTML = '';

    if (bands.length === 0) {
      bandList.innerHTML = `
        <div class="text-center py-8">
          <span class="text-6xl mb-4 block">🤔</span>
          <p class="text-gray-600">참여하신 밴드가 없네요!</p>
        </div>
      `;
      return;
    }

    bands.forEach(band => {
      const bandElement = document.createElement('div');
      bandElement.className = 'flex items-center p-4 border-2 border-purple-100 rounded-xl hover:border-purple-300 hover:bg-gradient-to-r hover:from-purple-50 hover:to-pink-50 cursor-pointer transition-all duration-200 transform hover:scale-105';
      bandElement.innerHTML = `
        <input type="radio" name="selected-band" value="${band.band_key}" class="mr-4 w-5 h-5 text-purple-600">
        <div class="relative">
          <img src="${band.cover}" alt="${band.name}" class="w-16 h-16 rounded-full mr-4 object-cover ring-4 ring-purple-200">
        </div>
        <div class="flex-1">
          <h3 class="font-bold text-gray-900 text-lg">${band.name}</h3>
          <p class="text-sm text-purple-600 flex items-center gap-1">
            <span>👥</span> ${band.member_count}명의 멤버
          </p>
        </div>
      `;

      bandElement.addEventListener('click', () => {
        // 다른 밴드들의 선택 해제
        document.querySelectorAll('input[name="selected-band"]').forEach(radio => {
          radio.checked = false;
          radio.closest('div').classList.remove('ring-4', 'ring-purple-400', 'bg-gradient-to-r', 'from-purple-100', 'to-pink-100');
        });

        const radio = bandElement.querySelector('input[type="radio"]');
        radio.checked = true;
        bandElement.classList.add('ring-4', 'ring-purple-400', 'bg-gradient-to-r', 'from-purple-100', 'to-pink-100');
        
        this.selectedBandKey = band.band_key;
        this.selectedBandName = band.name;
        
        // 삭제 섹션 활성화
        document.getElementById('delete-section').classList.remove('opacity-50');
        document.getElementById('delete-btn').disabled = false;
        
        // 이전 삭제 결과 숨기기
        this.clearDeleteResult();
        
        // 현재 선택된 삭제 타입에 따라 버튼 텍스트 업데이트
        this.updateDeleteButtonText();
      });

      bandList.appendChild(bandElement);
    });
  }

  async handleDelete() {
    if (!this.selectedBandKey) {
      this.showCustomAlert('밴드를 선택해 주세요', 'warning');
      return;
    }

    const selectedType = document.querySelector('input[name="delete-type"]:checked')?.value || 'all-comments';
    
    // 키워드 타입인 경우 키워드 입력 확인
    if (selectedType === 'keyword-comments') {
      const keyword = document.getElementById('keyword-text')?.value?.trim();
      if (!keyword) {
        this.showCustomAlert('키워드를 입력해 주세요', 'warning');
        return;
      }
    }

    try {
      // 1단계: 삭제할 개수 먼저 확인
      document.getElementById('delete-progress').classList.remove('hidden');
      document.getElementById('delete-btn').disabled = true;
      
      const count = await this.getDeleteCount(selectedType);
      document.getElementById('delete-progress').classList.add('hidden');
      
      if (count === 0) {
        this.showCustomAlert('삭제할 항목이 없습니다', 'info');
        document.getElementById('delete-btn').disabled = false;
        return;
      }

      // 2단계: 개수를 보여주며 확인
      let confirmMessage = '';
      switch (selectedType) {
        case 'all-comments':
          confirmMessage = `"${this.selectedBandName}" 밴드에 총 ${count}개의 댓글이 있습니다.\n\n정말로 모든 댓글을 쓸어 버리시겠습니까?`;
          break;
        case 'keyword-comments':
          const keyword = document.getElementById('keyword-text').value.trim();
          confirmMessage = `"${this.selectedBandName}" 밴드에서 "${keyword}" 키워드가 포함된 댓글이 ${count}개 발견되었습니다.\n\n정말로 이 ${count}개 댓글을 쓸어 버리시겠습니까?`;
          break;
        case 'all-posts':
          confirmMessage = `"${this.selectedBandName}" 밴드에 총 ${count}개의 게시글이 있습니다.\n\n⚠️ 게시글과 함께 모든 댓글도 삭제됩니다!\n\n정말로 모든 게시글을 쓸어 버리시겠습니까?`;
          break;
      }

      // 커스텀 confirm 사용
      this.showCustomConfirm(
        `${confirmMessage}\n\n이 작업은 되돌릴 수 없습니다.`,
        () => this.executeDelete(),
        () => {
          document.getElementById('delete-btn').disabled = false;
        }
      );
    } catch (error) {
      document.getElementById('delete-progress').classList.add('hidden');
      this.showDeleteResult(null, false, error.message);
      document.getElementById('delete-btn').disabled = false;
    }
  }

  async executeDelete() {
    try {
      // 3단계: 실제 삭제 실행
      document.getElementById('delete-progress').classList.remove('hidden');

      const data = await this.handleDeleteByType();
      document.getElementById('delete-progress').classList.add('hidden');

      if (data.success) {
        this.showDeleteResult(data.data, true);
      } else {
        throw new Error(data.error);
      }
    } catch (error) {
      document.getElementById('delete-progress').classList.add('hidden');
      this.showDeleteResult(null, false, error.message);
    }

    document.getElementById('delete-btn').disabled = false;
  }

  showDeleteResult(result, success, errorMessage = null) {
    const resultElement = document.getElementById('delete-result');
    
    if (success && result) {
      // 현재 선택된 삭제 타입 확인
      const selectedType = document.querySelector('input[name="delete-type"]:checked')?.value || 'all-comments';
      const isPostDelete = selectedType === 'all-posts';
      const itemType = isPostDelete ? '게시글' : '댓글';
      
      // 실패한 댓글들 저장
      if (result.failed > 0) {
        this.lastFailedComments = result.failed_comments;
      }
      resultElement.className = 'bg-gradient-to-r from-green-50 to-emerald-50 border-2 border-green-200 rounded-2xl p-6 shadow-lg';
      resultElement.innerHTML = `
        <div class="text-center">
          <div class="text-6xl mb-4">🎊</div>
          <h3 class="text-xl font-bold text-green-800 mb-2">🎉 쓸어 내기 완료!</h3>
          <div class="text-green-700">
            <p class="text-lg mb-2">총 <strong>${result.total}개</strong> ${itemType} 중</p>
            <div class="flex justify-center items-center gap-4 text-sm">
              <span class="bg-green-100 px-3 py-1 rounded-full">
                ✅ 성공: ${result.successful}개
              </span>
              ${result.failed > 0 ? `
                <span class="bg-red-100 px-3 py-1 rounded-full">
                  ❌ 실패: ${result.failed}개
                </span>
              ` : ''}
            </div>
            ${result.failed === 0 ? `
              <p class="mt-3 text-emerald-600 font-bold">✨ 모든 ${itemType}이 성공적으로 쓸어졌어요! ✨</p>
            ` : `
              <div class="mt-4">
                <p class="text-orange-600 mb-3">일부 ${itemType} 삭제에 실패했습니다.</p>
                <button onclick="window.bandCommentCleaner.retryFailed()" 
                        class="bg-gradient-to-r from-orange-500 to-red-500 text-white py-2 px-4 rounded-xl hover:from-orange-600 hover:to-red-600 font-bold transform hover:scale-105 transition-all duration-200">
                  🔄 실패한 ${itemType} 다시 시도
                </button>
              </div>
            `}
          </div>
        </div>
      `;
    } else {
      resultElement.className = 'bg-gradient-to-r from-red-50 to-pink-50 border-2 border-red-200 rounded-2xl p-6 shadow-lg';
      resultElement.innerHTML = `
        <div class="text-center">
          <div class="text-6xl mb-4">😢</div>
          <h3 class="text-xl font-bold text-red-800 mb-2">❌ 쓸어내기 실패</h3>
          <div class="text-red-700">
            <p class="bg-red-100 px-4 py-2 rounded-xl">
              ${errorMessage || '알 수 없는 오류가 발생했습니다. 다시 시도해주세요! 💔'}
            </p>
          </div>
        </div>
      `;
    }
    
    resultElement.classList.remove('hidden');
  }

  saveAuthData(authData) {
    localStorage.setItem('band_auth_data', JSON.stringify(authData));
  }

  loadAuthData() {
    const authData = localStorage.getItem('band_auth_data');
    return authData ? JSON.parse(authData) : null;
  }

  handleLogout() {
    this.showCustomConfirm(
      '정말 로그아웃하시겠습니까?',
      () => {
        // localStorage에서 인증 정보 삭제
        localStorage.removeItem('band_auth_data');
        
        // 페이지 새로고침
        window.location.reload();
      }
    );
  }

  async retryFailedComments() {
    if (!this.lastFailedComments || this.lastFailedComments.length === 0) {
      this.showCustomAlert('재시도할 실패한 댓글이 없습니다.', 'info');
      return;
    }

    if (!this.selectedBandKey) {
      this.showCustomAlert('밴드를 다시 선택해 주세요.', 'warning');
      return;
    }

    this.showCustomConfirm(
      `${this.lastFailedComments.length}개의 실패한 댓글을 다시 시도하시겠습니까?`,
      () => this.executeRetryFailedComments()
    );
  }

  async retryFailed() {
    if (!this.selectedBandKey) {
      this.showCustomAlert('밴드를 다시 선택해 주세요.', 'warning');
      return;
    }

    // 현재 선택된 삭제 타입 확인
    const selectedType = document.querySelector('input[name="delete-type"]:checked')?.value || 'all-comments';
    const isPostDelete = selectedType === 'all-posts';
    const itemType = isPostDelete ? '게시글' : '댓글';

    this.showCustomConfirm(
      `실패한 ${itemType}을 다시 시도하시겠습니까?`,
      () => this.executeRetryFailed()
    );
  }

  async executeRetryFailed() {
    // 진행 상황 표시
    const progressElement = document.getElementById('delete-progress');
    const resultElement = document.getElementById('delete-result');
    
    progressElement.classList.remove('hidden');
    resultElement.classList.add('hidden');

    try {
      // 현재 선택된 타입에 따라 재시도
      const data = await this.handleDeleteByType();
      
      if (data.success) {
        this.showDeleteResult(data.data, true);
      } else {
        throw new Error(data.error || 'Retry failed');
      }
    } catch (error) {
      this.showCustomAlert('재시도 중 오류가 발생했습니다', 'error');
    } finally {
      progressElement.classList.add('hidden');
    }
  }

  async executeRetryFailedComments() {
    // 진행 상황 표시
    const progressElement = document.getElementById('delete-progress');
    const resultElement = document.getElementById('delete-result');
    
    progressElement.classList.remove('hidden');
    resultElement.classList.add('hidden');

    try {
      // 전체 밴드 삭제 API로 재시도
      const response = await fetch(`${this.apiBaseUrl}/bands/${this.selectedBandKey}/comments?access_token=${this.authData.access_token}`, {
        method: 'DELETE'
      });
      
      const data = await response.json();
      
      if (data.success) {
        this.showDeleteResult(data.data, true);
      } else {
        throw new Error(data.error || 'Retry failed');
      }
    } catch (error) {
      this.showCustomAlert('재시도 중 오류가 발생했습니다', 'error');
    } finally {
      progressElement.classList.add('hidden');
    }
  }

  updateDeleteButtonText() {
    const selectedType = document.querySelector('input[name="delete-type"]:checked')?.value || 'all-comments';
    const deleteBtn = document.getElementById('delete-btn');
    
    if (this.selectedBandName) {
      let buttonText = '';
      switch (selectedType) {
        case 'all-comments':
          buttonText = `🧹 "${this.selectedBandName}" 밴드의 모든 댓글 쓸어 버리기 ✨`;
          break;
        case 'keyword-comments':
          buttonText = `🧹 "${this.selectedBandName}" 밴드의 키워드 댓글 쓸어 버리기 ✨`;
          break;
        case 'all-posts':
          buttonText = `🧹 "${this.selectedBandName}" 밴드의 모든 게시글 쓸어 버리기 ✨`;
          break;
      }
      deleteBtn.innerHTML = buttonText;
    }
  }

  handleDeleteTypeChange() {
    const selectedType = document.querySelector('input[name="delete-type"]:checked').value;
    const keywordInput = document.getElementById('keyword-input');
    
    // 키워드 입력 필드 표시/숨김
    if (selectedType === 'keyword-comments') {
      keywordInput.classList.remove('hidden');
    } else {
      keywordInput.classList.add('hidden');
    }
    
    // 이전 삭제 결과 숨기기
    this.clearDeleteResult();
    
    // 버튼 텍스트 업데이트
    this.updateDeleteButtonText();
  }

  async handleDeleteByType() {
    const selectedType = document.querySelector('input[name="delete-type"]:checked').value;
    
    switch (selectedType) {
      case 'all-comments':
        return await this.deleteAllComments();
      case 'keyword-comments':
        return await this.deleteCommentsByKeyword();
      case 'all-posts':
        return await this.deleteAllPosts();
      default:
        throw new Error('알 수 없는 삭제 타입입니다.');
    }
  }

  async deleteAllComments() {
    const response = await fetch(`${this.apiBaseUrl}/bands/${this.selectedBandKey}/comments?access_token=${this.authData.access_token}`, {
      method: 'DELETE'
    });
    return await response.json();
  }

  async deleteCommentsByKeyword() {
    const keyword = document.getElementById('keyword-text').value.trim();
    
    if (!keyword) {
      throw new Error('키워드를 입력해 주세요.');
    }
    
    const response = await fetch(`${this.apiBaseUrl}/bands/${this.selectedBandKey}/comments/keyword?access_token=${this.authData.access_token}&keyword=${encodeURIComponent(keyword)}`, {
      method: 'DELETE'
    });
    return await response.json();
  }

  async deleteAllPosts() {
    const response = await fetch(`${this.apiBaseUrl}/bands/${this.selectedBandKey}/posts?access_token=${this.authData.access_token}`, {
      method: 'DELETE'
    });
    return await response.json();
  }

  async getDeleteCount(selectedType) {
    switch (selectedType) {
      case 'all-comments':
        return await this.getCommentsCount();
      case 'keyword-comments':
        return await this.getKeywordCommentsCount();
      case 'all-posts':
        return await this.getPostsCount();
      default:
        throw new Error('알 수 없는 삭제 타입입니다.');
    }
  }

  async getCommentsCount() {
    const response = await fetch(`${this.apiBaseUrl}/bands/${this.selectedBandKey}/comments/count?access_token=${this.authData.access_token}`);
    
    const contentType = response.headers.get("content-type");
    if (!contentType || !contentType.includes("application/json")) {
      throw new Error(`Server error (${response.status})`);
    }
    
    const data = await response.json();
    if (data.success) {
      return data.count;
    } else {
      throw new Error('Operation failed');
    }
  }

  async getKeywordCommentsCount() {
    const keyword = document.getElementById('keyword-text').value.trim();
    const response = await fetch(`${this.apiBaseUrl}/bands/${this.selectedBandKey}/comments/count/keyword?access_token=${this.authData.access_token}&keyword=${encodeURIComponent(keyword)}`);
    
    const contentType = response.headers.get("content-type");
    if (!contentType || !contentType.includes("application/json")) {
      throw new Error(`Server error (${response.status})`);
    }
    
    const data = await response.json();
    if (data.success) {
      return data.count;
    } else {
      throw new Error('Operation failed');
    }
  }

  async getPostsCount() {
    const response = await fetch(`${this.apiBaseUrl}/bands/${this.selectedBandKey}/posts/count?access_token=${this.authData.access_token}`);
    
    const contentType = response.headers.get("content-type");
    if (!contentType || !contentType.includes("application/json")) {
      throw new Error(`Server error (${response.status})`);
    }
    
    const data = await response.json();
    if (data.success) {
      return data.count;
    } else {
      throw new Error('Operation failed');
    }
  }

  // 이전 삭제 결과 숨기기
  clearDeleteResult() {
    const resultElement = document.getElementById('delete-result');
    if (resultElement) {
      resultElement.classList.add('hidden');
      resultElement.innerHTML = '';
    }
    
    // 실패한 댓글 목록도 초기화
    this.lastFailedComments = null;
  }

  // 커스텀 알럿창
  showCustomAlert(message, type = 'info') {
    const alertId = 'custom-alert-' + Date.now();
    const alertHtml = `
      <div id="${alertId}" class="fixed inset-0 z-50 flex items-center justify-center bg-black bg-opacity-50 animate-fade-in" onclick="document.getElementById('${alertId}').remove()">
        <div class="bg-white rounded-2xl p-6 max-w-sm mx-4 shadow-2xl transform animate-scale-in">
          <div class="text-center">
            <p class="text-gray-800 text-lg">${message}</p>
          </div>
        </div>
      </div>
    `;
    
    document.body.insertAdjacentHTML('beforeend', alertHtml);
    
    // 자동으로 5초 후 제거
    setTimeout(() => {
      const alertElement = document.getElementById(alertId);
      if (alertElement) {
        alertElement.remove();
      }
    }, 5000);
  }

  // 커스텀 confirm창
  showCustomConfirm(message, onConfirm, onCancel = null) {
    const confirmId = 'custom-confirm-' + Date.now();
    const confirmHtml = `
      <div id="${confirmId}" class="fixed inset-0 z-50 flex items-center justify-center bg-black bg-opacity-50 animate-fade-in">
        <div class="bg-white rounded-2xl p-6 max-w-md mx-4 shadow-2xl transform animate-scale-in">
          <div class="text-center">
            <p class="text-gray-800 mb-6 whitespace-pre-line text-lg">${message}</p>
            <div class="flex gap-3">
              <button onclick="document.getElementById('${confirmId}').remove(); if(window.customConfirmCancel) window.customConfirmCancel()" 
                      class="flex-1 bg-gray-300 hover:bg-gray-400 text-gray-800 py-3 px-6 rounded-xl font-bold transform hover:scale-105 transition-all duration-200">
                취소
              </button>
              <button onclick="document.getElementById('${confirmId}').remove(); if(window.customConfirmAction) window.customConfirmAction()" 
                      class="flex-1 bg-gradient-to-r from-red-500 to-pink-500 text-white py-3 px-6 rounded-xl hover:from-red-600 hover:to-pink-600 font-bold transform hover:scale-105 transition-all duration-200">
                확인
              </button>
            </div>
          </div>
        </div>
      </div>
    `;
    
    // 전역 함수로 콜백 등록
    window.customConfirmAction = onConfirm;
    window.customConfirmCancel = onCancel;
    
    document.body.insertAdjacentHTML('beforeend', confirmHtml);
  }
}

// DOM 로드 완료 후 앱 시작
document.addEventListener('DOMContentLoaded', () => {
  new BandCommentCleaner();
});