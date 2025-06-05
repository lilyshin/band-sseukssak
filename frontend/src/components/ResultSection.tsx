import React from 'react';
import { DeleteResult } from '../services/api';

interface ResultSectionProps {
  result: DeleteResult | null;
  success: boolean;
  error?: string;
  onRetryFailed?: () => void;
  show: boolean;
}

export const ResultSection: React.FC<ResultSectionProps> = ({ 
  result, 
  success, 
  error, 
  onRetryFailed, 
  show 
}) => {
  if (!show) return null;

  if (success && result) {
    const hasFailures = result.failed > 0;
    
    return (
      <div className="bg-gradient-to-r from-green-50 to-emerald-50 border-2 border-green-200 rounded-2xl p-6 shadow-lg mt-4">
        <div className="text-center">
          <div className="text-6xl mb-4">🎊</div>
          <h3 className="text-xl font-bold text-green-800 mb-2">🎉 쓸어 내기 완료!</h3>
          <div className="text-green-700">
            <p className="text-lg mb-2">총 <strong>{result.total}개</strong> 항목 중</p>
            <div className="flex justify-center items-center gap-4 text-sm">
              <span className="bg-green-100 px-3 py-1 rounded-full">
                ✅ 성공: {result.successful}개
              </span>
              {hasFailures && (
                <span className="bg-red-100 px-3 py-1 rounded-full">
                  ❌ 실패: {result.failed}개
                </span>
              )}
            </div>
            {!hasFailures ? (
              <p className="mt-3 text-emerald-600 font-bold">✨ 모든 항목이 성공적으로 쓸어졌어요! ✨</p>
            ) : (
              <div className="mt-4">
                <p className="text-orange-600 mb-3">일부 항목 삭제에 실패했습니다.</p>
                
                {/* 실패 원인 표시 */}
                {result.failed_comments && result.failed_comments.length > 0 && (
                  <div className="bg-orange-50 border border-orange-200 rounded-lg p-3 mb-3 text-sm">
                    <p className="font-bold text-orange-800 mb-2">❌ 실패 원인:</p>
                    <div className="space-y-1">
                      {/* 실패 원인을 그룹화하여 중복 제거 */}
                      {Array.from(new Set(
                        result.failed_comments.map(item => item.error?.message || "알 수 없는 오류")
                      )).slice(0, 2).map((reason, index) => (
                        <p key={index} className="text-orange-700">
                          • {reason}
                        </p>
                      ))}
                      {Array.from(new Set(
                        result.failed_comments.map(item => item.error?.message || "알 수 없는 오류")
                      )).length > 2 && (
                        <p className="text-orange-600 italic">
                          외 기타 오류들...
                        </p>
                      )}
                    </div>
                  </div>
                )}
                
                {onRetryFailed && (
                  <button 
                    onClick={onRetryFailed}
                    className="bg-gradient-to-r from-orange-500 to-red-500 text-white py-2 px-4 rounded-xl hover:from-orange-600 hover:to-red-600 font-bold transform hover:scale-105 transition-all duration-200"
                  >
                    🔄 실패한 항목 다시 시도
                  </button>
                )}
              </div>
            )}
          </div>
        </div>
      </div>
    );
  }

  // 실패한 경우
  return (
    <div className="bg-gradient-to-r from-red-50 to-pink-50 border-2 border-red-200 rounded-2xl p-6 shadow-lg mt-4">
      <div className="text-center">
        <div className="text-6xl mb-4">😢</div>
        <h3 className="text-xl font-bold text-red-800 mb-2">❌ 쓸어내기 실패</h3>
        <div className="text-red-700">
          <p className="bg-red-100 px-4 py-2 rounded-xl">
            {error || '알 수 없는 오류가 발생했습니다. 다시 시도해주세요! 💔'}
          </p>
        </div>
      </div>
    </div>
  );
};