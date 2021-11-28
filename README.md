# 오픈 마켓 프로잭트

### shapiro, 승기

---

## 주요 학습 개념

1. 모델, 네트워크 타입 구현
   + URLSession을 이용한 RestAPI 구현
   + Multi-part-form을 이용한 미디어 파일 통신 구현
2. 네트워크 UnitTest
   + Mock객체를 생성하여 네트워크 테스트 구현
3. Collection View를 이용한 목록 화면 구현



## 1. 모델, 네트워크 타입 구현

---

URLSession: 관련된 네트워크 데이터 전송 작업 그룹을 조정하는 객체이다.



### 구현 중 문제점

1. 각각의 http 메서드에 따라 각기 다른 통신을 위한 메서드 구현 ex) requestGet, requestPost ...

2. 실제 통신을 하는 request 메서드 안에서 타입캐스팅을 통한 분기처리로 인해 RestAPI를 위한 네트워크 타입이 아닌 하나의 API를 위해서만 존재하는 네트워크 타입 구현
3. 어떤 contentType  ( ex) multi-part- form, json ...) 으로 body를 만들지에 대한 처리가 되어있지 않고 하나의 api를 위해서만 구현되어있음



### 해결 방법

1. **실제 통신을 위한 request 메서드 하나로 해야 되는 이유?**

   + endPoint는 하나로 통일하는게 유지보수에 용이하다고 판단

2. **RestAPI를 위한 프로토콜 설계후 필요한 기능을 담아 각각의 상황에 맞추도록 변경**

   ```swift
   protocol APIable {
       var contentType: ContentType { get }
       var requestType: RequestType { get }
       var url: String { get }
       var param: [String: String?]? { get }
       var mediaFile: [Media]? { get }
   }
   ```

3. **타입캐스팅을 이용해 어떤 api인지 판단하는 방법의 문제?**

   + 새로운 api가 생겼을때 또다른 분기가 생기는 문제 발생 유지보수면에서 안좋다고 판단

4. **기존에 서버에 보내기위한 API 모델을 Struct로 구현했던 부분을 Dictionary 형태의 파라미터로 보내도록 변경**

   + 기존 구현 방법인 Struct로 API 모델을 만들었을때 어떤 특성을 가진 API인지 판단하기 위해 타입캐스팅을 사용했던 문제 수정

5. **enum 형태로 각각의 형태에 맞는 위의 APIable 프로토콜을 채택한 API 케이스 구현**

   ```swift
   enum GetAPI: APIable {
       
       case lookUpProductList(page: Int, contentType: ContentType)
       case lookUpProduct(id: String, contentType: ContentType)
       
       var contentType: ContentType {
           switch self {
           case .lookUpProductList(page: _, contentType: let contentType):
               return contentType
           case .lookUpProduct(id: _,  contentType: let contentType):
               return contentType
           }
       }
       
       var requestType: RequestType {
           switch self {
           case .lookUpProductList:
               return .get
           case .lookUpProduct:
               return .get
           }
       }
       
       var url: String {
           switch self{
           case .lookUpProductList(page: let page, contentType: _):
               return "\(NetworkManager.baseUrl)/items/\(page)"
           case .lookUpProduct(id: let id, contentType: _):
               return "\(NetworkManager.baseUrl)/items/\(id)"
           }
       }
       
       var param: [String : String?]? {
           switch self {
           case .lookUpProductList:
               return nil
           case .lookUpProduct:
               return nil
           }
       }
       
       var mediaFile: [Media]? {
           switch self {
           case .lookUpProduct:
               return nil
           case .lookUpProductList:
               return nil
           }
       }
   }
   ```

6. **실제 통신을 위한 NetworkManager request 메서드 구현부**

   APIable을 채택한 모델을 인자로 넣어주면 동작하도록 구현

   ```swift
   func request(apiModel: APIable, completion: @escaping URLSessionResult) {
           guard let url = URL(string: apiModel.url) else {
               completion(.failure(NetworkError.invalidURL))
               return
           }
           
           var request = URLRequest(url: url)
           request.httpMethod = apiModel.requestType.method
           request.httpBody = createDataBody(parameter: apiModel.param, contentType: apiModel.contentType, imageFile: apiModel.mediaFile)
           
           switch apiModel.contentType {
           case .multiPartForm:
               request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
           case .jsonData:
               request.setValue("application/json", forHTTPHeaderField: "Content-Type")
           case .noBody:
               break
           }
           
           session.dataTask(with: request) { data, response, error in
               if let error = error {
                   completion(.failure(error))
                   return
               }
               
               guard let response = response as? HTTPURLResponse, (200...299).contains(response.statusCode) else {
                   completion(.failure(NetworkError.failResponse))
                   return
               }
               
               guard let data = data else {
                   completion(.failure(NetworkError.invalidData))
                   return
               }
               completion(.success(data))
           } .resume()
       }
   ```

7. **contentType에 따른 body 생성 로직 변경**

   + 기존에는 post가 multi-part-form 으로만 보내도록 api 문서에 적혀있어서 따로 처리를 하지 않았음
   + 다른 특성을 가진 api가 생성되도라도 대응가능하도록 변경
   + APIable 프로토콜에 contentType을 명시하도록 한다음 그에따른 처리를 통한 body 생성 로직 구현

   ```swift
   private func createDataBody(parameter: [String: String?]?, contentType: ContentType, imageFile: [Media]?) -> Data? {
           var body = Data()
           let lineBreak = "\r\n"
           
           if let modelParameter = parameter {
               if contentType == .multiPartForm {
                   for (key, value) in modelParameter {
                       body.append(convertTextField(key: key, value: "\(value ?? "")"))
                   }
                   guard let modelImages = imageFile else {
                       body.append("--\(boundary)--\(lineBreak)")
                       return body
                   }
                   for image in modelImages {
                       body.append(convertFileField(key: image.key, source: image.filename, mimeType: image.mimeType, value: image.data))
                   }
                   body.append("--\(boundary)--\(lineBreak)")
               } else {
                   if let data = parsingManager.encodingModel(model: parameter) {
                       body = data
                   }
               }
           } else {
               return nil
           }
           return body
       }
   ```



## 2.  네트워크 UnitTest

---

Mock 객체: Mock Object란 프로그램을 테스트 할 경우 테스트를 수행할 모듈과 연결되는 외부의 다른 서비스나 모듈들을 실제 사용하는 모듈을 사용하지 않고 실제의 모듈을 "흉내"내는 "가짜" 모듈을 작성하여 테스트의 효용성을 높이는데 사용하는 객체이다.



### 구현중 문제점

1. 실제로 통신이 잘 이루어지는지 테스트할 때 실제로 서버와 통신을 하면서 테스트하였다.
2. 의존성 주입을 통한 Mock객체 생성의 어려움 겪음



### 해결 방법

1. **테스트할때 외부의 서비스를 이용하면 안되는 이유?**

   + 개발단계의 코드를 실제 서버와 통신할 경우 라이브 서비스나 테스트 서버에 문제가 생길 가능성이 있다. 클라이언트 내에서 Mock을 이용한 1차적인 테스트가 필요하다고 판단

2. **의존성 주입을 하기 위한 NetworkManager 구현**

   URLsession을 내부가 아닌 외부에서 초기화 할수 있도록 변경

   ```swift
   class NetworkManager {
       private let session: Networkable
       
       init(session: Networkable = URLSession.shared) {
           self.session = session
       }
   }
   ```

3. **외부에서 초기화 하는 이유?**

   + session 프로퍼티가 변동된 모듈이 들어오더라도 위처럼 Networkable이라는 추상화된 모듈에 의존하게 되면서 의존성이 떨어진다.
   + 테스트에 용이해진다. Networkable을 채택한 Mock객체 활용이 가능해진다.

4. **MockURLSession 객체 생성**

   1. 위의 Networkable을 이용하여 dataTask를 구현하도록 요구하고 completionHandler를 테스트에 맞게 외부에서 설정해주도록 한다음 테스트의 결과값을 예상할 수 있도록 설정하는 방법

   2. 기존의 존재하는 URLProtocol 을 채택하여 새로운 URLProtocol구현부를 작성하여 방법 completionHandler를 외부에서 설정하는 방법

   이번 프로젝트에서는 2번 방법으로 구현했다. UnitTest는 둘다 정상적으로 작동할것이라고 생각한다. 하지만 Networkable 프로토콜을 만들어 놓고 추상화의 용도로만 사용하고 기능들을 요구하지 않고 사용을 제대로 못해본 점은 아쉽다고 생각한다.

   ```swift
   class MockURLProtocol: URLProtocol {
       static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data?))?
       
       class override func canInit(with request: URLRequest) -> Bool {
           true
       }
       
       class override func canonicalRequest(for request: URLRequest) -> URLRequest {
           return request
       }
       
       override func startLoading() {
           do {
               guard let handler = MockURLProtocol.requestHandler else {
                   throw NetworkError.invalidHandler
               } 
               
               let (response, data) = try handler(request)
               
               client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
               
               if let data = data {
                   client?.urlProtocol(self, didLoad: data)
               } else {
                   throw NetworkError.invalidData
               }
               
               client?.urlProtocolDidFinishLoading(self)
           } catch {
               client?.urlProtocol(self, didFailWithError: error)
           }
       }
       
       override func stopLoading() {
           
       }
   }
   ```

5. **실제 테스트 구현**

   MockURLProtocol의 Handler에 테스트를 하고 싶은 결과값을 넣어놓고 예상대로 잘 작동하는지에 대한 테스트를 구현했다.

   ```swift
   func test_response가404일때_get을_요청하면_error가뜬다() {
           //given
           MockURLProtocol.requestHandler = { request in
               let response = HTTPURLResponse(url: self.url, statusCode: 404, httpVersion: nil, headerFields: nil)!
               let data = NSDataAsset(name: "Item")!.data
               
               return (response, data)
           }
           
           //when
           var expectResult = false
           sut.request(apiModel: dummyGetItem) { [self] (networkResult) in
               switch networkResult {
               case .success:
                   XCTFail("통과 되었음 에러!!")
               case .failure:
                   expectResult = true
               }
               expectation.fulfill()
           }
           
           //then
           wait(for: [expectation], timeout: 10)
           XCTAssertTrue(expectResult)
       }
   ```

   

## 3. Collection View를 이용한 목록 화면 구현

---

Collection View: 정렬된 데이터 항목 컬렉션을 관리하고 사용자 지정 가능한 레이아웃을 사용하여 표시하는 객체이다.



### 구현중 문제점

1. View와 Controller의 역할
2. Collection View를 새로 그려주는 문제
3. 비동기적으로 이미지를 각각의 셀에 그릴때 문제점



### 해결 방법

1. **기존에 셀의 label에 어떤것을 그려줄지 cell안에서 처리**

   + 기존에 단순히 그려주는 값을 분기처리하는 계산 로직은 View의 역할에 들어가도 되겠다고 생각하고 구현했다.

   + 뷰의 역할에 만들어지는 값을 계산하는 로직을 넣으면 변경 시점을 찾기가 힘들어진다고 판단 
   + Controller에서 이 계산이 된 후 Label.text = 값 이런식으로만 넣어주는 방법으로 변경하였다.

2. **서버에서 받아오는 page가 늘어나면서 새롭게 collection view를 그려줘야 했다.**

   + reloadData() 와 insertItems(at:) 메서드가 해당 역할을 할 수 있었다.
   + 프로젝트에서는 reloadData() 메서드를 사용했지만 collecionView를 완전히 처음부터 구성하기에 비용이 많이 발생한다.  증가된 부분만 collectionView를 다시 그리도록 insertItems(at:)을 이용하지 않은 점이 아쉽다.

3. **각 셀에 image 그려주기**

   처음 구현을 했을때 상품의 목록안에 있는 image가 데이터화 되어 이미 넘어와있다고 생각하였다.

   하지만 data가 넘어 온것이 아니라 해당 image가 저장되어있는 특정 주소가 넘어 온것

   이후에 아래와 같은 순서로 image를 그려주었다.

   1. 서버에 현재 페이지의 상품 목록을 요청
   2. 해당 상품리스트에 대한 정보를 각각의 cell에 뿌리기
   3. 비동기적으로 cell의 이미지가 저장된 url을 통해 통신 및 UI그리기

4. **데이터를 로드할때 URLSession과 Data(contentsOf:)의 차이점**

   + 처음 이미지를 그려줄때 Data(contentsOf:)를 사용했다. 하지만 공식문서를 보니 스레드가 블락될 수도 있다는 얘기를 보았다.

     Don't use this synchronous initializer to request network-based URLs.
     For network-based URLs, this method can block the current thread for tens of seconds on a slow network, resulting in a poor user experience, and in iOS, may cause your app to be terminated. Instead, for non-file URLs, consider using the dataTask(with:completionHandler:) method of the URLSession class. See Fetching Website Data into Memory for an example. 

     이라는 내용이 존재했고 현재의 상황에서는 URLSession의 dataTask가 맞다고 판단하였다.

