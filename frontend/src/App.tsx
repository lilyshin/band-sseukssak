import React, { useState, useEffect } from 'react';
import { Layout } from './components/Layout';
import { AuthSection } from './components/AuthSection';
import { BandSection } from './components/BandSection';
import { DeleteSection } from './components/DeleteSection';
import { ResultSection } from './components/ResultSection';
import { BandAPIService, AuthData, Band, DeleteResult, AuthStorage } from './services/api';
import { AlertModal, ConfirmModal } from './components/CustomModal';
import './App.css';

function App() {
  const [authData, setAuthData] = useState<AuthData | null>(null);
  const [selectedBand, setSelectedBand] = useState<Band | null>(null);
  const [deleteResult, setDeleteResult] = useState<{
    result: DeleteResult | null;
    success: boolean;
    error?: string;
    show: boolean;
  }>({ result: null, success: false, show: false });
  const [error, setError] = useState<string | null>(null);
  const [logoutModal, setLogoutModal] = useState(false);

  // 컴포넌트 마운트 시 저장된 인증 정보 로드 및 OAuth 콜백 처리
  useEffect(() => {
    // 저장된 인증 정보 로드
    const savedAuthData = AuthStorage.load();
    if (savedAuthData) {
      setAuthData(savedAuthData);
    }

    // URL에서 OAuth 콜백 파라미터 확인
    const urlParams = new URLSearchParams(window.location.search);
    const success = urlParams.get('success');
    const errorParam = urlParams.get('error');
    const accessToken = urlParams.get('access_token');
    const userKey = urlParams.get('user_key');
    
    if (success === 'true' && accessToken && userKey) {
      // 토큰 정보로 AuthData 구성
      const tokenData: AuthData = {
        access_token: accessToken,
        user_key: userKey,
        name: '밴드 사용자', // 기본값
      };
      
      setAuthData(tokenData);
      AuthStorage.save(tokenData);
      
      // URL 정리
      window.history.replaceState({}, document.title, window.location.pathname);
    } else if (success === 'false' && errorParam) {
      setError('인증 중 오류가 발생했습니다: ' + decodeURIComponent(errorParam));
      // URL 정리
      window.history.replaceState({}, document.title, window.location.pathname);
    }
  }, []);

  const handleAuthCallback = async (code: string) => {
    try {
      const response = await BandAPIService.handleAuthCallback(code);
      
      if (response.success && response.data) {
        setAuthData(response.data);
        AuthStorage.save(response.data);
        
        // URL 정리
        window.history.replaceState({}, document.title, window.location.pathname);
      } else {
        setError('토큰 발급 실패: ' + JSON.stringify(response.error));
      }
    } catch (err) {
      setError('콜백 처리 실패: ' + (err as Error).message);
    }
  };

  const handleAuthSuccess = (newAuthData: AuthData) => {
    setAuthData(newAuthData);
    AuthStorage.save(newAuthData);
  };

  const handleLogout = () => {
    setLogoutModal(true);
  };

  const confirmLogout = () => {
    AuthStorage.clear();
    setAuthData(null);
    setSelectedBand(null);
    setDeleteResult({ result: null, success: false, show: false });
    setLogoutModal(false);
  };

  const handleBandSelect = (band: Band) => {
    setSelectedBand(band);
  };

  const handleDeleteResult = (result: DeleteResult | null, success: boolean, error?: string) => {
    setDeleteResult({
      result,
      success,
      error,
      show: true
    });
  };

  const handleClearResults = () => {
    setDeleteResult({ result: null, success: false, show: false });
  };

  const handleRetryFailed = () => {
    // 현재 결과를 숨기고 직접 재삭제 실행
    setDeleteResult({ result: null, success: false, show: false });
    // DeleteSection에 직접 삭제 실행 신호를 보냄
    window.dispatchEvent(new CustomEvent('executeRetryDeletion'));
  };

  return (
    <Layout>
      <AuthSection 
        authData={authData}
        onAuthSuccess={handleAuthSuccess}
        onLogout={handleLogout}
      />
      
      <BandSection 
        authData={authData}
        selectedBand={selectedBand}
        onBandSelect={handleBandSelect}
        onClearResults={handleClearResults}
      />
      
      <DeleteSection 
        authData={authData}
        selectedBand={selectedBand}
        onDeleteResult={handleDeleteResult}
      />
      
      <ResultSection 
        result={deleteResult.result}
        success={deleteResult.success}
        error={deleteResult.error}
        onRetryFailed={handleRetryFailed}
        show={deleteResult.show}
      />

      {/* 에러 모달 */}
      {error && (
        <AlertModal 
          message={error}
          type="error"
          onClose={() => setError(null)}
        />
      )}

      {/* 로그아웃 확인 모달 */}
      {logoutModal && (
        <ConfirmModal
          message="정말 로그아웃하시겠습니까?"
          onConfirm={confirmLogout}
          onCancel={() => setLogoutModal(false)}
        />
      )}
    </Layout>
  );
}

export default App;
