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
    
    
    private var statisticService: StatisticService?
    private var presenter: MovieQuizPresenter!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        presenter = MovieQuizPresenter(viewController: self)
        
        imageView.layer.cornerRadius = 20
        statisticService = StatisticServiceImplementation()
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
        imageView.image = step.image
        questionText.text = step.question
        counterLabel.text = step.questionNumber
    }
    
    func show(quiz result: QuizResultsViewModel) {
        if presenter.isLastQuestion() {
            statisticService?.store(correct: presenter.correctAnswers, total: presenter.questionsAmount)
            
            guard let gamesCount = statisticService?.gamesCount else { return }
            guard let bestGame = statisticService?.bestGame else { return }
            guard let totalAccuracy = statisticService?.totalAccuracy else { return }
            
            let text = """
        Ваш результат: \(presenter.correctAnswers)/\(presenter.questionsAmount)
        Количество сыгранных квизов: \(gamesCount)
        Рекорд: \(bestGame.correct)/\(bestGame.total) (\(bestGame.date.dateTimeString))
        Средняя точность: \(String(format: "%.2f", totalAccuracy))%
        """
            
            AlertPresenter(delegate: self).showResult(alertModel: AlertModel(title: result.title,
                                                                             message: text,
                                                                             buttonText: result.buttonText) { [weak self] in
                self?.presenter.restartGame()
            })
        }
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
    
    func showAnswerResult(isCorrect: Bool) {
        presenter.didAnswer(isCorrectAnswer: isCorrect)
        
        imageView.layer.masksToBounds = true
        imageView.layer.borderWidth = 8
        imageView.layer.borderColor = isCorrect ? UIColor(named: "ypGreen")?.cgColor : UIColor(named: "ypRed")?.cgColor
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {[weak self] in
            guard let self = self else { return }
            self.imageView.layer.borderWidth = 0
            self.presenter.showNextQuestionOrResults()
        }
    }
}
