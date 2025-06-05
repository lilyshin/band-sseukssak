import React, { useState, useEffect } from 'react';
import { BandAPIService, Band, AuthData } from '../services/api';
import { AlertModal } from './CustomModal';

interface BandSectionProps {
  authData: AuthData | null;
  selectedBand: Band | null;
  onBandSelect: (band: Band) => void;
  onClearResults: () => void;
}

export const BandSection: React.FC<BandSectionProps> = ({ 
  authData, 
  selectedBand, 
  onBandSelect, 
  onClearResults 
}) => {
  const [bands, setBands] = useState<Band[]>([]);
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (authData) {
      loadBands();
    }
  }, [authData]);

  const loadBands = async () => {
    if (!authData) return;

    try {
      setIsLoading(true);
      setError(null);

      const response = await BandAPIService.getBands(authData.access_token);
      
      if (response.success && response.data?.result_data?.bands) {
        setBands(response.data.result_data.bands);
      } else {
        setError('밴드 목록을 불러오는데 실패했습니다.');
      }
    } catch (err) {
      setError('네트워크 오류가 발생했습니다. 다시 시도해 주세요.');
    } finally {
      setIsLoading(false);
    }
  };

  const handleBandClick = (band: Band) => {
    onBandSelect(band);
    onClearResults(); // 이전 삭제 결과 지우기
  };

  const isEnabled = !!authData;
  const isExpanded = isEnabled;

  return (
    <>
      <div className={`bg-white/80 backdrop-blur-sm shadow-xl rounded-2xl border border-blue-100 mb-6 transition-all duration-500 ${!isEnabled ? 'opacity-50' : ''}`}>
        <div className="flex items-center gap-3 p-6 pb-0">
          <div className={`w-8 h-8 rounded-full flex items-center justify-center text-white font-bold ${isEnabled ? 'bg-green-500' : 'bg-gray-400'}`}>
            {isEnabled ? '✓' : '2'}
          </div>
          <h2 className="text-xl font-bold text-gray-800">밴드 선택</h2>
          {!isEnabled && <span className="text-sm text-gray-400 ml-auto">🔒 인증 후 이용 가능</span>}
        </div>
        
        {isExpanded ? (
          <div className="p-6 pt-4 space-y-2 animate-fade-in">
            {isLoading ? (
              <div className="text-center py-8">
                <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-purple-600 mx-auto mb-4"></div>
                <p className="text-gray-500">밴드 목록을 불러오는 중...</p>
              </div>
            ) : bands.length === 0 ? (
              <div className="text-center py-8">
                <span className="text-6xl mb-4 block">🤔</span>
                <p className="text-gray-600">참여하신 밴드가 없네요!</p>
                <button 
                  onClick={loadBands}
                  className="mt-4 px-6 py-3 bg-gradient-to-r from-blue-500 to-purple-500 text-white rounded-xl hover:from-blue-600 hover:to-purple-600 font-bold transform hover:scale-105 transition-all duration-200"
                >
                  🔄 다시 시도하기
                </button>
              </div>
            ) : (
              bands.map((band) => (
                <div
                  key={band.band_key}
                  onClick={() => handleBandClick(band)}
                  className={`flex items-center p-4 border rounded-xl cursor-pointer transition-all duration-200 transform hover:scale-105 ${
                    selectedBand?.band_key === band.band_key
                      ? 'border-purple-400 bg-gradient-to-r from-purple-100 to-pink-100 ring-2 ring-purple-300 ring-opacity-50 shadow-lg'
                      : 'border-purple-100 hover:border-purple-300 hover:bg-gradient-to-r hover:from-purple-50 hover:to-pink-50 hover:shadow-md'
                  }`}
                >
                  <input 
                    type="radio" 
                    name="selected-band" 
                    value={band.band_key}
                    checked={selectedBand?.band_key === band.band_key}
                    onChange={() => {}} // onClick에서 처리
                    className="mr-4 w-5 h-5 text-purple-600"
                  />
                  <div className="relative">
                    <img 
                      src={band.cover} 
                      alt={band.name}
                      className="w-16 h-16 rounded-full mr-4 object-cover ring-4 ring-purple-200"
                    />
                  </div>
                  <div className="flex-1">
                    <h3 className="font-bold text-gray-900 text-lg">{band.name}</h3>
                    <p className="text-sm text-purple-600 flex items-center gap-1">
                      <span>👥</span> {band.member_count}명의 멤버
                    </p>
                  </div>
                </div>
              ))
            )}
          </div>
        ) : (
          <div className="p-6 pt-4 text-center py-8">
            <span className="text-4xl mb-2 block">😴</span>
            <p className="text-gray-500">먼저 계정 인증을 완료해 주세요~</p>
          </div>
        )}
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