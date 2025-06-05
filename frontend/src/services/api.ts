import axios, { AxiosResponse } from 'axios';

// Phoenix 백엔드 API 기본 URL (개발 환경)
const API_BASE_URL = process.env.REACT_APP_API_URL || 'http://localhost:4000/api';

// Axios 인스턴스 생성
const apiClient = axios.create({
  baseURL: API_BASE_URL,
  timeout: 120000, // 120초 타임아웃 (댓글 삭제는 시간이 오래 걸릴 수 있음)
  headers: {
    'Content-Type': 'application/json',
  },
});

// 응답 인터셉터로 에러 처리
apiClient.interceptors.response.use(
  (response: AxiosResponse) => response,
  (error) => {
    console.error('API 요청 실패:', error);
    return Promise.reject(error);
  }
);

// 타입 정의들
export interface AuthData {
  access_token: string;
  user_key: string;
  name: string;
  profile_image_url?: string;
}

export interface Band {
  band_key: string;
  name: string;
  cover: string;
  member_count: number;
}

export interface DeleteResult {
  total: number;
  successful: number;
  failed: number;
  failed_comments?: Array<{ comment_key: string; error: any }>;
}

export interface ApiResponse<T = any> {
  success: boolean;
  data?: T;
  error?: string;
  count?: number;
}

// API 서비스 클래스
export class BandAPIService {
  /**
   * Band OAuth 인증 URL 요청
   */
  static async getAuthUrl(): Promise<ApiResponse<{ auth_url: string }>> {
    try {
      const response = await apiClient.get('/auth/band');
      return response.data;
    } catch (error) {
      throw new Error('인증 URL 생성 실패');
    }
  }

  /**
   * OAuth 콜백 처리 (인증 코드로 토큰 획득)
   */
  static async handleAuthCallback(code: string): Promise<ApiResponse<AuthData>> {
    try {
      const response = await apiClient.post('/auth/oauth/token', { code });
      return response.data;
    } catch (error) {
      throw new Error('인증 토큰 획득 실패');
    }
  }

  /**
   * 사용자가 가입한 밴드 목록 조회
   */
  static async getBands(accessToken: string): Promise<ApiResponse<{ result_data: { bands: Band[] } }>> {
    try {
      const response = await apiClient.get(`/bands?access_token=${accessToken}`);
      return response.data;
    } catch (error) {
      throw new Error('밴드 목록 조회 실패');
    }
  }

  /**
   * 특정 밴드의 모든 댓글 개수 조회
   */
  static async getCommentsCount(accessToken: string, bandKey: string): Promise<ApiResponse> {
    try {
      const response = await apiClient.get(`/bands/${bandKey}/comments/count?access_token=${accessToken}`);
      return response.data;
    } catch (error) {
      throw new Error('댓글 개수 조회 실패');
    }
  }

  /**
   * 특정 밴드의 키워드 댓글 개수 조회
   */
  static async getKeywordCommentsCount(
    accessToken: string, 
    bandKey: string, 
    keyword: string
  ): Promise<ApiResponse> {
    try {
      const response = await apiClient.get(
        `/bands/${bandKey}/comments/count/keyword?access_token=${accessToken}&keyword=${encodeURIComponent(keyword)}`
      );
      return response.data;
    } catch (error) {
      throw new Error('키워드 댓글 개수 조회 실패');
    }
  }

  /**
   * 특정 밴드의 게시글 개수 조회
   */
  static async getPostsCount(accessToken: string, bandKey: string): Promise<ApiResponse> {
    try {
      const response = await apiClient.get(`/bands/${bandKey}/posts/count?access_token=${accessToken}`);
      return response.data;
    } catch (error) {
      throw new Error('게시글 개수 조회 실패');
    }
  }

  /**
   * 특정 밴드의 모든 댓글 삭제
   */
  static async deleteAllComments(accessToken: string, bandKey: string): Promise<ApiResponse<DeleteResult>> {
    try {
      const response = await apiClient.delete(`/bands/${bandKey}/comments?access_token=${accessToken}`);
      return response.data;
    } catch (error: any) {
      console.error('댓글 삭제 API 에러:', error);
      
      if (error.code === 'ECONNABORTED') {
        throw new Error('요청 시간이 초과되었습니다. 다시 시도해 주세요.');
      }
      
      if (error.response?.data?.error) {
        throw new Error(`댓글 삭제 실패: ${error.response.data.error}`);
      }
      
      throw new Error('댓글 삭제 실패');
    }
  }

  /**
   * 특정 밴드의 키워드 댓글 삭제
   */
  static async deleteKeywordComments(
    accessToken: string, 
    bandKey: string, 
    keyword: string
  ): Promise<ApiResponse<DeleteResult>> {
    try {
      const response = await apiClient.delete(
        `/bands/${bandKey}/comments/keyword?access_token=${accessToken}&keyword=${encodeURIComponent(keyword)}`
      );
      return response.data;
    } catch (error: any) {
      console.error('키워드 댓글 삭제 API 에러:', error);
      
      if (error.code === 'ECONNABORTED') {
        throw new Error('요청 시간이 초과되었습니다. 다시 시도해 주세요.');
      }
      
      if (error.response?.data?.error) {
        throw new Error(`키워드 댓글 삭제 실패: ${error.response.data.error}`);
      }
      
      throw new Error('키워드 댓글 삭제 실패');
    }
  }

  /**
   * 특정 밴드의 모든 게시글 삭제
   */
  static async deleteAllPosts(accessToken: string, bandKey: string): Promise<ApiResponse<DeleteResult>> {
    try {
      const response = await apiClient.delete(`/bands/${bandKey}/posts?access_token=${accessToken}`);
      return response.data;
    } catch (error: any) {
      console.error('게시글 삭제 API 에러:', error);
      
      if (error.code === 'ECONNABORTED') {
        throw new Error('요청 시간이 초과되었습니다. 다시 시도해 주세요.');
      }
      
      if (error.response?.data?.error) {
        throw new Error(`게시글 삭제 실패: ${error.response.data.error}`);
      }
      
      throw new Error('게시글 삭제 실패');
    }
  }
}

// 로컬 스토리지에서 인증 정보 관리
export class AuthStorage {
  private static readonly AUTH_KEY = 'band_auth_data';

  static save(authData: AuthData): void {
    localStorage.setItem(this.AUTH_KEY, JSON.stringify(authData));
  }

  static load(): AuthData | null {
    const data = localStorage.getItem(this.AUTH_KEY);
    return data ? JSON.parse(data) : null;
  }

  static clear(): void {
    localStorage.removeItem(this.AUTH_KEY);
  }
}

export default BandAPIService;