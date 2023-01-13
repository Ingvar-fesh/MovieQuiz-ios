import UIKit

struct Movie: Codable {
    let id: String
    let rank: Int
    let title: String
    let fullTitle: String
    let year: Int
    let image: String
    let crew: String
    let imDbRating: Float
    let imDbRatingCount: Int
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        
        let rank = try container.decode(String.self, forKey: .rank)
        self.rank = Int(rank)!
        
        title = try container.decode(String.self, forKey: .title)
        fullTitle = try container.decode(String.self, forKey: .fullTitle)
        
        let year = try container.decode(String.self, forKey: .year)
        self.year = Int(year)!
        
        image = try container.decode(String.self, forKey: .image)
        crew = try container.decode(String.self, forKey: .crew)
        
        let imDbRating = try container.decode(String.self, forKey: .imDbRating)
        self.imDbRating = Float(imDbRating)!
        
        let imDbRatingCount = try container.decode(String.self, forKey: .imDbRatingCount)
        self.imDbRatingCount = Int(imDbRatingCount)!
    }
}

struct Top: Decodable {
    let items: [Movie]
}

final class MovieQuizViewController: UIViewController {
    
    // MARK: - Lifecycle
    @IBOutlet private var imageView: UIImageView!
    @IBOutlet private var questionText: UILabel!
    @IBOutlet private var activityIndicator: UIActivityIndicatorView!
    @IBOutlet private var counterLabel: UILabel!
    
    private var presenter: MovieQuizPresenter!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        presenter = MovieQuizPresenter(viewController: self)
        
        imageView.layer.cornerRadius = 20
        showLoadingIndicator()
    }
    
    func didReceiveNextQuestion(question: QuizQuestion?) {
        presenter.didReceiveNextQuestion(question: question)
    }
    
    
    func showLoadingIndicator() {
        activityIndicator.isHidden = false
        activityIndicator.startAnimating()
    }
    


    @IBAction private func noButtonClicked(_ sender: UIButton) {
        presenter.noButtonClicked()
    }
    
    @IBAction private func yesButtonClicked(_ sender: UIButton) {
        presenter.yesButtonClicked()
    }
    
    
    func show(quiz step: QuizStepViewModel) {
        imageView.layer.borderWidth = 0
        imageView.image = step.image
        questionText.text = step.question
        counterLabel.text = step.questionNumber
    }
    
    func show(quiz result: QuizResultsViewModel) {
        let message = presenter.makeResultMessage()

        let alert = UIAlertController(
            title: result.title,
            message: message,
            preferredStyle: .alert)

            let action = UIAlertAction(title: result.buttonText, style: .default) { [weak self] _ in
                guard let self = self else { return }

                self.presenter.restartGame()
            }

        alert.addAction(action)

        self.present(alert, animated: true, completion: nil)
    }
    
    func showNetworkError(message: String) {
        hideLoadingIndicator()
        AlertPresenter(delegate: self).showResult(alertModel: AlertModel(title: "Ошибка",
                                                                         message: message,
                                                                         buttonText: "Попробовать ещё раз") { [weak self] in
            self?.presenter.restartGame()
        })
    }
    
    func hideLoadingIndicator() {
        activityIndicator.isHidden = true
        activityIndicator.stopAnimating()
    }
    
    func highlightImageBorder(isCorrectAnswer: Bool) {
        imageView.layer.masksToBounds = true
        imageView.layer.borderWidth = 8
        imageView.layer.borderColor = isCorrectAnswer ? UIColor(named: "ypGreen")?.cgColor : UIColor(named: "ypRed")?.cgColor
    }
}
