package com.wellsfargo.payments.config;

import com.wellsfargo.payments.entity.CardMaster;
import com.wellsfargo.payments.repository.CardMasterRepository;
import com.wellsfargo.payments.service.CardService;
import org.springframework.batch.core.Job;
import org.springframework.batch.core.Step;
import org.springframework.batch.core.job.builder.JobBuilder;
import org.springframework.batch.core.repository.JobRepository;
import org.springframework.batch.core.step.builder.StepBuilder;
import org.springframework.batch.core.step.tasklet.Tasklet;
import org.springframework.batch.repeat.RepeatStatus;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.transaction.PlatformTransactionManager;

/**
 * Spring Batch configuration - replaces JCL batch job orchestration.
 * Defines jobs for card issuance pipeline and settlement pipeline.
 */
@Configuration
public class BatchConfig {

    private final JobRepository jobRepository;
    private final PlatformTransactionManager transactionManager;
    private final CardService cardService;

    public BatchConfig(JobRepository jobRepository,
                       PlatformTransactionManager transactionManager,
                       CardService cardService) {
        this.jobRepository = jobRepository;
        this.transactionManager = transactionManager;
        this.cardService = cardService;
    }

    /**
     * PILOAD0 - Load sample data tasklet.
     * Replaces JCL PILOAD0 step that loads initial card data.
     */
    @Bean
    public Tasklet loadSampleDataTasklet() {
        return (contribution, chunkContext) -> {
            cardService.loadSampleData();
            return RepeatStatus.FINISHED;
        };
    }

    /**
     * PICRD400 - Card renewal tasklet.
     * Replaces JCL step that runs the renewal batch.
     */
    @Bean
    public Tasklet cardRenewalTasklet() {
        return (contribution, chunkContext) -> {
            cardService.renewCards(60);
            return RepeatStatus.FINISHED;
        };
    }

    @Bean
    public Step loadSampleDataStep() {
        return new StepBuilder("loadSampleData", jobRepository)
                .tasklet(loadSampleDataTasklet(), transactionManager)
                .build();
    }

    @Bean
    public Step cardRenewalStep() {
        return new StepBuilder("cardRenewal", jobRepository)
                .tasklet(cardRenewalTasklet(), transactionManager)
                .build();
    }

    /**
     * PI Batch Pipeline Job - replaces JCL PIPROC.
     * Steps: PILOAD0 → PICRD400
     */
    @Bean
    public Job piPipelineJob() {
        return new JobBuilder("piPipelineJob", jobRepository)
                .start(loadSampleDataStep())
                .next(cardRenewalStep())
                .build();
    }
}
