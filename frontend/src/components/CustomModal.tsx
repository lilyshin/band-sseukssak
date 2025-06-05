import React, { useEffect } from 'react';

interface AlertModalProps {
  message: string;
  onClose: () => void;
  type?: 'info' | 'warning' | 'error' | 'success';
}

export const AlertModal: React.FC<AlertModalProps> = ({ message, onClose, type = 'info' }) => {
  useEffect(() => {
    const timer = setTimeout(() => {
      onClose();
    }, 5000);

    return () => clearTimeout(timer);
  }, [onClose]);

  return (
    <div 
      className="fixed inset-0 z-50 flex items-center justify-center bg-black bg-opacity-50 animate-fade-in"
      onClick={onClose}
    >
      <div className="bg-white rounded-2xl p-6 max-w-sm mx-4 shadow-2xl transform animate-scale-in">
        <div className="text-center">
          <p className="text-gray-800 text-lg">{message}</p>
        </div>
      </div>
    </div>
  );
};

interface ConfirmModalProps {
  message: string;
  onConfirm: () => void;
  onCancel: () => void;
  isHtml?: boolean;
}

export const ConfirmModal: React.FC<ConfirmModalProps> = ({ 
  message, 
  onConfirm, 
  onCancel, 
  isHtml = false 
}) => {
  const handleConfirm = () => {
    onConfirm();
  };

  const handleCancel = () => {
    onCancel();
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black bg-opacity-50 animate-fade-in">
      <div className="bg-white rounded-2xl p-6 max-w-md mx-4 shadow-2xl transform animate-scale-in">
        <div className="text-center">
          <div className="text-gray-800 mb-6 text-lg">
            {isHtml ? (
              <div dangerouslySetInnerHTML={{ __html: message }} />
            ) : (
              message
            )}
          </div>
          <div className="flex gap-3">
            <button
              onClick={handleCancel}
              className="flex-1 bg-gray-300 hover:bg-gray-400 text-gray-800 py-3 px-6 rounded-xl font-bold transform hover:scale-105 transition-all duration-200"
            >
              취소
            </button>
            <button
              onClick={handleConfirm}
              className="flex-1 bg-gradient-to-r from-red-500 to-pink-500 text-white py-3 px-6 rounded-xl hover:from-red-600 hover:to-pink-600 font-bold transform hover:scale-105 transition-all duration-200"
            >
              확인
            </button>
          </div>
        </div>
      </div>
    </div>
  );
};