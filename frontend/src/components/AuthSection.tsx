import React, { useState } from 'react';
import { BandAPIService, AuthData } from '../services/api';
import { AlertModal } from './CustomModal';

interface AuthSectionProps {
  authData: AuthData | null;
  onAuthSuccess: (authData: AuthData) => void;
  onLogout: () => void;
}

export const AuthSection: React.FC<AuthSectionProps> = ({ authData, onAuthSuccess, onLogout }) => {
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const handleAuth = async () => {
    try {
      setIsLoading(true);
      setError(null);

      const response = await BandAPIService.getAuthUrl();
      if (response.success && response.data?.auth_url) {
        window.location.href = response.data.auth_url;
      } else {
        setError(response.error || '인증 URL 생성 실패');
      }
    } catch (err) {
      setError('인증 요청 실패: ' + (err as Error).message);
    } finally {
      setIsLoading(false);
    }
  };

  const isAuthenticated = !!authData;

  return (
    <>
      <div className="bg-white/80 backdrop-blur-sm shadow-xl rounded-2xl border border-purple-100 mb-6 transition-all duration-500">
        <div className="flex items-center gap-3 p-6 pb-0">
          <div className={`w-8 h-8 rounded-full flex items-center justify-center text-white font-bold ${isAuthenticated ? 'bg-green-500' : 'bg-blue-500'}`}>
            {isAuthenticated ? '✓' : '1'}
          </div>
          <h2 className="text-xl font-bold text-gray-800">밴드 계정 인증</h2>
          {isAuthenticated && (
            <button 
              onClick={onLogout}
              className="ml-auto bg-gray-100 hover:bg-gray-200 text-gray-700 px-4 py-2 rounded-xl text-sm font-medium transition-colors border border-gray-300"
            >
              🚪 로그아웃
            </button>
          )}
        </div>
        
        <div className="p-6 pt-4">
          {!isAuthenticated ? (
            <>
              <div className="mb-6 text-left">
                <p className="text-purple-600 text-sm">👇 아래 버튼을 클릭해 주세요!</p>
              </div>

              <div>
                <button 
                  onClick={handleAuth}
                  disabled={isLoading}
                  className="w-full bg-gradient-to-r from-pink-500 via-purple-500 to-blue-500 text-white py-4 px-6 rounded-2xl hover:from-pink-600 hover:via-purple-600 hover:to-blue-600 focus:outline-none focus:ring-4 focus:ring-purple-300 font-bold text-lg transform hover:scale-105 transition-all duration-200 shadow-lg disabled:opacity-50 disabled:transform-none"
                >
                  {isLoading ? '🔄 처리 중...' : '🌈 밴드 계정으로 로그인하기 ✨'}
                </button>
                <p className="mt-4 text-center text-sm text-gray-500 flex items-center justify-center gap-1">
                  <span>🔒</span>
                  밴드 공식 OAuth로 안전하게 로그인돼요!
                  <span>💖</span>
                </p>
              </div>
            </>
          ) : (
            <div className="flex items-center justify-center bg-green-50 border border-green-200 rounded-xl p-4">
              <span className="text-2xl mr-2">🎊</span>
              <span className="text-green-800 font-bold">로그인 완료!</span>
              <span className="text-2xl ml-2">🎉</span>
            </div>
          )}
        </div>
      </div>

      {error && (
        <AlertModal 
          message={error}
          type="error"
          onClose={() => setError(null)}
        />
      )}
    </>
  );
};