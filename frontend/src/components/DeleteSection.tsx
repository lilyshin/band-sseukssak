import React, { useState, useEffect } from 'react';
import { BandAPIService, Band, AuthData, DeleteResult } from '../services/api';
import { AlertModal, ConfirmModal } from './CustomModal';

export type DeleteType = 'all-comments' | 'keyword-comments' | 'all-posts';

interface DeleteSectionProps {
  authData: AuthData | null;
  selectedBand: Band | null;
  onDeleteResult: (result: DeleteResult | null, success: boolean, error?: string) => void;
}

export const DeleteSection: React.FC<DeleteSectionProps> = ({ 
  authData, 
  selectedBand, 
  onDeleteResult 
}) => {
  const [deleteType, setDeleteType] = useState<DeleteType>('all-comments');
  const [keyword, setKeyword] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [confirmModal, setConfirmModal] = useState<{
    show: boolean;
    message: string;
    onConfirm: () => void;
  } | null>(null);
  const [deleteProgress, setDeleteProgress] = useState<{
    current: number;
    total: number;
  } | null>(null);

  const isEnabled = !!(authData && selectedBand);
  const isExpanded = isEnabled;

  // 재시도 이벤트 리스너 등록
  useEffect(() => {
    const handleRetryEvent = async () => {
      // 재시도를 위해 현재 설정으로 확인 없이 바로 삭제 실행
      if (authData && selectedBand) {
        try {
          setIsLoading(true);
          setError(null);
          
          // 재시도 시에는 실제 개수를 다시 확인
          let estimatedCount = 1; // 기본값
          try {
            const count = await getDeleteCount(deleteType);
            estimatedCount = count;
          } catch (err) {
            console.warn('개수 조회 실패, 기본값 사용:', err);
          }
          setDeleteProgress({ current: 0, total: estimatedCount });
          
          // 진행률 시뮬레이션
          const progressInterval = setInterval(() => {
            setDeleteProgress(prev => {
              if (!prev) return null;
              // 실제 개수에 따라 적절한 증가량 계산
              const incrementAmount = Math.max(1, Math.random() * (prev.total / 10));
              const newCurrent = Math.min(prev.current + incrementAmount, prev.total - 1);
              return { current: Math.floor(newCurrent), total: prev.total };
            });
          }, 2000);
          
          const result = await executeDelete(deleteType);
          clearInterval(progressInterval);
          setDeleteProgress({ current: estimatedCount, total: estimatedCount });
          
          setTimeout(() => {
            onDeleteResult(result, true);
          }, 1000);
          
        } catch (err) {
          onDeleteResult(null, false, (err as Error).message);
        } finally {
          setIsLoading(false);
          setDeleteProgress(null);
        }
      }
    };

    window.addEventListener('executeRetryDeletion', handleRetryEvent);
    
    return () => {
      window.removeEventListener('executeRetryDeletion', handleRetryEvent);
    };
  }, [authData, selectedBand, deleteType, keyword]);

  const getDeleteCount = async (type: DeleteType): Promise<number> => {
    if (!authData || !selectedBand) throw new Error('인증 정보 또는 밴드가 선택되지 않았습니다.');

    let response;
    switch (type) {
      case 'all-comments':
        response = await BandAPIService.getCommentsCount(authData.access_token, selectedBand.band_key);
        break;
      case 'keyword-comments':
        if (!keyword.trim()) throw new Error('키워드를 입력해 주세요.');
        response = await BandAPIService.getKeywordCommentsCount(authData.access_token, selectedBand.band_key, keyword);
        break;
      case 'all-posts':
        response = await BandAPIService.getPostsCount(authData.access_token, selectedBand.band_key);
        break;
    }

    if (response.success && response.data && typeof response.data.count === 'number') {
      return response.data.count;
    }
    throw new Error('개수 조회 실패');
  };

  const executeDelete = async (type: DeleteType): Promise<DeleteResult> => {
    if (!authData || !selectedBand) throw new Error('인증 정보 또는 밴드가 선택되지 않았습니다.');

    let response;
    switch (type) {
      case 'all-comments':
        response = await BandAPIService.deleteAllComments(authData.access_token, selectedBand.band_key);
        break;
      case 'keyword-comments':
        if (!keyword.trim()) throw new Error('키워드를 입력해 주세요.');
        response = await BandAPIService.deleteKeywordComments(authData.access_token, selectedBand.band_key, keyword);
        break;
      case 'all-posts':
        response = await BandAPIService.deleteAllPosts(authData.access_token, selectedBand.band_key);
        break;
    }

    if (response.success && response.data) {
      return response.data;
    }
    throw new Error(response.error || '삭제 실패');
  };

  const handleDelete = async () => {
    if (!isEnabled) {
      setError('밴드를 선택해 주세요.');
      return;
    }

    if (deleteType === 'keyword-comments' && !keyword.trim()) {
      setError('키워드를 입력해 주세요.');
      return;
    }

    try {
      setIsLoading(true);
      setError(null);

      // 1단계: 삭제할 개수 확인
      const count = await getDeleteCount(deleteType);
      setIsLoading(false);

      if (count === 0) {
        setError('삭제할 항목이 없습니다.');
        return;
      }

      // 2단계: 사용자 확인
      let confirmMessage = '';
      
      switch (deleteType) {
        case 'all-comments':
          confirmMessage = `"${selectedBand?.name}" 밴드에 총 <span class="text-red-600 font-bold">${count}개</span>의 댓글이 있습니다.<br><br>정말로 모든 댓글을 쓸어 버리시겠습니까?`;
          break;
        case 'keyword-comments':
          confirmMessage = `"${selectedBand?.name}" 밴드에서 "${keyword}" 키워드가 포함된 댓글이 <span class="text-red-600 font-bold">${count}개</span> 발견되었습니다.<br><br>정말로 이 <span class="text-red-600 font-bold">${count}개</span> 댓글을 쓸어 버리시겠습니까?`;
          break;
        case 'all-posts':
          confirmMessage = `"${selectedBand?.name}" 밴드에 총 <span class="text-red-600 font-bold">${count}개</span>의 게시글이 있습니다.<br><br>⚠️ 게시글과 함께 모든 댓글도 삭제됩니다!<br><br>정말로 모든 게시글을 쓸어 버리시겠습니까?`;
          break;
      }

      setConfirmModal({
        show: true,
        message: `${confirmMessage}<br><br><span class="text-gray-600">이 작업은 되돌릴 수 없습니다.</span>`,
        onConfirm: async () => {
          setConfirmModal(null);
          try {
            setIsLoading(true);
            setDeleteProgress({ current: 0, total: count });
            
            // 진행률 시뮬레이션 (실제 삭제 과정에서 업데이트)
            const progressInterval = setInterval(() => {
              setDeleteProgress(prev => {
                if (!prev) return null;
                // 실제 개수에 따라 적절한 증가량 계산
                const incrementAmount = Math.max(1, Math.random() * (prev.total / 8));
                const newCurrent = Math.min(prev.current + incrementAmount, prev.total - 1);
                return { current: Math.floor(newCurrent), total: prev.total };
              });
            }, 2000); // 2초마다 진행률 업데이트
            
            const result = await executeDelete(deleteType);
            clearInterval(progressInterval);
            setDeleteProgress({ current: count, total: count }); // 완료 상태
            
            // 완료 메시지 잠깐 보여주고 결과 표시
            setTimeout(() => {
              onDeleteResult(result, true);
            }, 1000);
            
          } catch (err) {
            onDeleteResult(null, false, (err as Error).message);
          } finally {
            setIsLoading(false);
            setDeleteProgress(null);
          }
        }
      });

    } catch (err) {
      setIsLoading(false);
      setError((err as Error).message);
    }
  };

  const getButtonText = () => {
    if (!selectedBand) return '🧹 밴드를 선택해 주세요 ✨';
    
    switch (deleteType) {
      case 'all-comments':
        return `🧹 "${selectedBand.name}" 밴드의 모든 댓글 쓸어 버리기 ✨`;
      case 'keyword-comments':
        return `🧹 "${selectedBand.name}" 밴드의 키워드 댓글 쓸어 버리기 ✨`;
      case 'all-posts':
        return `🧹 "${selectedBand.name}" 밴드의 모든 게시글 쓸어 버리기 ✨`;
      default:
        return '🧹 쓸어 버리기 ✨';
    }
  };

  return (
    <>
      <div className={`bg-white/80 backdrop-blur-sm shadow-xl rounded-2xl border border-red-100 mb-6 transition-all duration-500 ${!isEnabled ? 'opacity-50' : ''}`}>
        <div className="flex items-center gap-3 p-6 pb-0">
          <div className={`w-8 h-8 rounded-full flex items-center justify-center text-white font-bold ${isEnabled ? 'bg-green-500' : 'bg-gray-400'}`}>
            {isEnabled ? '✓' : '3'}
          </div>
          <h2 className="text-xl font-bold text-gray-800">쓸어 내기 실행</h2>
          {!isEnabled && <span className="text-sm text-gray-400 ml-auto">🔒 밴드 선택 후 이용 가능</span>}
        </div>
        
        {isExpanded ? (
          <div className="p-6 pt-4 animate-fade-in">
            {/* 삭제 타입 선택 */}
            <div className="mb-6">
              <div className="space-y-3">
                <label className="flex items-center p-3 border-2 border-purple-200 rounded-xl hover:border-purple-400 cursor-pointer bg-gradient-to-r from-purple-50 to-pink-50">
                  <input 
                    type="radio" 
                    name="delete-type" 
                    value="all-comments"
                    checked={deleteType === 'all-comments'}
                    onChange={(e) => setDeleteType(e.target.value as DeleteType)}
                    className="mr-3 w-4 h-4 text-purple-600"
                  />
                  <div className="flex-1">
                    <span className="font-bold text-purple-800">모든 댓글 쓸어 내기</span>
                    <p className="text-sm text-purple-600">선택한 밴드의 모든 댓글을 삭제합니다</p>
                  </div>
                </label>
                
                <label className="flex items-center p-3 border-2 border-orange-200 rounded-xl hover:border-orange-400 cursor-pointer bg-gradient-to-r from-orange-50 to-yellow-50">
                  <input 
                    type="radio" 
                    name="delete-type" 
                    value="keyword-comments"
                    checked={deleteType === 'keyword-comments'}
                    onChange={(e) => setDeleteType(e.target.value as DeleteType)}
                    className="mr-3 w-4 h-4 text-orange-600"
                  />
                  <div className="flex-1">
                    <span className="font-bold text-orange-800">키워드 댓글만 쓸어 내기</span>
                    <p className="text-sm text-orange-600">특정 단어가 포함된 댓글만 삭제합니다</p>
                  </div>
                </label>
                
                <label className="flex items-center p-3 border-2 border-red-200 rounded-xl hover:border-red-400 cursor-pointer bg-gradient-to-r from-red-50 to-pink-50">
                  <input 
                    type="radio" 
                    name="delete-type" 
                    value="all-posts"
                    checked={deleteType === 'all-posts'}
                    onChange={(e) => setDeleteType(e.target.value as DeleteType)}
                    className="mr-3 w-4 h-4 text-red-600"
                  />
                  <div className="flex-1">
                    <span className="font-bold text-red-800">모든 게시글 쓸어 내기</span>
                    <p className="text-sm text-red-600">선택한 밴드의 모든 게시글을 삭제합니다 (댓글도 함께 삭제됨)</p>
                  </div>
                </label>
              </div>
            </div>
            
            {/* 키워드 입력 */}
            {deleteType === 'keyword-comments' && (
              <div className="mb-6">
                <h3 className="text-lg font-bold text-gray-700 mb-3 flex items-center gap-2">
                  <span>🔍</span> 삭제할 키워드 입력
                </h3>
                <input 
                  type="text" 
                  value={keyword}
                  onChange={(e) => setKeyword(e.target.value)}
                  placeholder="삭제할 댓글에 포함된 단어를 입력하세요"
                  className="w-full p-3 border-2 border-orange-200 rounded-xl focus:border-orange-400 focus:outline-none text-gray-800"
                />
                <p className="text-sm text-orange-600 mt-2">💡 대소문자 구분 없이 검색됩니다</p>
              </div>
            )}
            
            {/* 경고 메시지 */}
            <div className="bg-gradient-to-r from-red-50 to-pink-50 border border-red-200 rounded-xl p-4 mb-4">
              <div className="flex">
                <div className="flex-shrink-0">
                  <span className="text-2xl">⚠️</span>
                </div>
                <div className="ml-3">
                  <p className="text-sm text-red-700">
                    <strong>🚨 주의해 주세요!</strong> 선택한 타입에 따라 댓글 또는 게시글이 영구적으로 쓸어집니다. 
                    <br />이 작업은 되돌릴 수 없어요! 💔
                  </p>
                </div>
              </div>
            </div>

            {/* 삭제 버튼 */}
            <button 
              onClick={handleDelete}
              disabled={!isEnabled || isLoading}
              className="w-full bg-gradient-to-r from-red-500 to-pink-500 text-white py-4 px-6 rounded-2xl hover:from-red-600 hover:to-pink-600 focus:outline-none focus:ring-4 focus:ring-red-300 font-bold text-lg transform hover:scale-105 transition-all duration-200 shadow-lg disabled:opacity-50 disabled:transform-none"
            >
              {isLoading ? '🚀 쓸어 내는 중...' : getButtonText()}
            </button>

            {/* 진행 상황 표시 */}
            {isLoading && (
              <div className="mt-4">
                <div className="bg-gradient-to-r from-blue-50 to-purple-50 border border-blue-200 rounded-xl p-6">
                  <div className="text-center space-y-3">
                    <div className="flex items-center justify-center gap-3">
                      <div className="animate-spin rounded-full h-6 w-6 border-b-2 border-purple-600"></div>
                      <span className="text-2xl">🧹</span>
                    </div>
                    <div className="space-y-2">
                      <p className="text-blue-800 font-bold text-lg">쓱싹쓱싹 쓸어 내는 중... 잠시만 기다려 주세요!</p>
                      {deleteProgress && (
                        <div className="space-y-2">
                          <p className="text-purple-700 font-semibold">
                            {deleteProgress.current}개 / {deleteProgress.total}개 처리 중...
                          </p>
                          <div className="w-full bg-gray-200 rounded-full h-2">
                            <div 
                              className="bg-gradient-to-r from-purple-500 to-pink-500 h-2 rounded-full transition-all duration-300"
                              style={{ width: `${(deleteProgress.current / deleteProgress.total) * 100}%` }}
                            ></div>
                          </div>
                        </div>
                      )}
                      <p className="text-sm text-gray-600">💡 쿨 타임 제한으로 인해 시간이 다소 걸릴 수 있습니다</p>
                    </div>
                  </div>
                </div>
              </div>
            )}
          </div>
        ) : (
          <div className="p-6 pt-4 text-center py-8">
            <span className="text-4xl mb-2 block">🔒</span>
            <p className="text-gray-500">밴드를 선택해 주세요</p>
          </div>
        )}
      </div>

      {/* 에러 모달 */}
      {error && (
        <AlertModal 
          message={error}
          type="error"
          onClose={() => setError(null)}
        />
      )}

      {/* 확인 모달 */}
      {confirmModal?.show && (
        <ConfirmModal
          message={confirmModal.message}
          isHtml={true}
          onConfirm={confirmModal.onConfirm}
          onCancel={() => setConfirmModal(null)}
        />
      )}
    </>
  );
};