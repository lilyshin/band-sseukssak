import React from 'react';

interface LayoutProps {
  children: React.ReactNode;
}

export const Layout: React.FC<LayoutProps> = ({ children }) => {
  return (
    <div className="min-h-screen bg-gradient-to-br from-pink-50 via-purple-50 to-blue-50 py-6">
      <div className="max-w-2xl mx-auto px-4">
        <div className="text-center mb-8">
          <div className="text-6xl mb-4 animate-bounce">🧹</div>
          <h1 className="text-4xl font-bold bg-gradient-to-r from-pink-500 via-purple-500 to-blue-500 bg-clip-text text-transparent mb-2">
            밴쓱싹
          </h1>
          <p className="text-gray-600 text-sm">💫 한번에 깔끔하게! 귀찮은 댓글들을 모두 쓸어 버리세요! 💫</p>
        </div>
        
        {children}
      </div>
    </div>
  );
};