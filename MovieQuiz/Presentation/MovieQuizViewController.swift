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

final class MovieQuizViewController: UIViewController, QuestionFactoryDelegate {
    // MARK: - Lifecycle
    @IBOutlet private var imageView: UIImageView!
    @IBOutlet private var questionText: UILabel!
    @IBOutlet private var counterLabel: UILabel!
    
    private var currentQuestionIndex = 0
    private var correctAnswers = 0
    
    private let questionsAmount = 10
    private var questionFactory: QuestionFactoryProtocol = QuestionFactory()
    private var currentQuestion: QuizQuestion?
    private var statisticService: StatisticService = StatisticServiceImplementation()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        questionFactory.delegate = self
        questionFactory.requestQuestion()
    }
    
    func didReceiveNextQuestion(question: QuizQuestion?) {
        guard let question = question else {
            return
        }
        currentQuestion = question
        let viewModel = convert(model: question)
        DispatchQueue.main.async { [weak self] in
            self?.show(quiz: viewModel)
        }
    }
    

    @IBAction private func noButtonClicked(_ sender: Any) {
        guard let currentQuestion = currentQuestion else {
            return
        }
        showAnswerResult(isCorrect: !currentQuestion.correctAnswer)
    }
    
    @IBAction private func yesButtonClicked(_ sender: Any) {
        guard let currentQuestion = currentQuestion else {
            return
        }
        showAnswerResult(isCorrect: currentQuestion.correctAnswer)
    }
    
    private func show(quiz step: QuizStepViewModel) {
        imageView.image = step.image
        questionText.text = step.question
        counterLabel.text = step.questionNumber
    }
    
    private func show(quiz result: QuizResultsViewModel) {
        statisticService.store(correct: correctAnswers, total: questionsAmount)
        let resultMessage = "Ваш результат: \(correctAnswers)/\(questionsAmount)\nКоличество сыгранных квизов: \(statisticService.gamesCount)\nРекорд: \(statisticService.bestGame.correct)/\(questionsAmount) (\(statisticService.bestGame.date.dateTimeString))\nСредняя точность: \(String(format: "%.2f", statisticService.totalAccuracy * 100))%"
        AlertPresenter(delegate: self).showResult(alertModel: AlertModel(title: result.title,
                                                     message: resultMessage,
                                                     buttonText: result.buttonText) { [weak self] in
            self?.currentQuestionIndex = 0
            self?.correctAnswers = 0
            self?.questionFactory.requestQuestion()
        })
    }
    
    private func showAnswerResult(isCorrect: Bool) {
        if isCorrect {
            correctAnswers += 1
        }
        
        imageView.layer.masksToBounds = true
        imageView.layer.borderWidth = 8
        imageView.layer.borderColor = isCorrect ? UIColor(named: "ypGreen")?.cgColor : UIColor(named: "ypRed")?.cgColor
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {[weak self] in
            guard let self = self else {
                return
            }
            self.showNextQuestionOrResults()
        }
    }
    
    private func convert(model: QuizQuestion) -> QuizStepViewModel {
        return QuizStepViewModel(image: UIImage(named: model.image) ?? UIImage(), question: model.text,
            questionNumber: "\(currentQuestionIndex + 1)/\(questionsAmount)")
    }
    
    private func showNextQuestionOrResults() {
        if currentQuestionIndex == questionsAmount - 1 {
            imageView.layer.borderWidth = 0
            let text = "Ваш результат: \(correctAnswers) из 10"
            let viewModel = QuizResultsViewModel(
                title: "Этот раунд окончен!",
                text: text,
                buttonText: "Сыграть ещё раз")
            show(quiz: viewModel)
        } else {
            imageView.layer.borderWidth = 0
            currentQuestionIndex += 1
            questionFactory.requestQuestion()
        }
    }
}
